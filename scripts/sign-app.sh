#!/usr/bin/env bash
set -euo pipefail

# Usage: sign-app.sh <APP_PATH> <IDENTITY> [KEYCHAIN_PATH]
#
# Sparkle の XPC サービスとヘルパーは必要な entitlements が部品ごとに異なるため、
# --deep を使わず Sparkle の公式手順の順序で内側から署名する。
# https://sparkle-project.org/documentation/sandboxing/#code-signing
APP_PATH="${1:?APP_PATH is required}"
IDENTITY="${2:?IDENTITY is required}"
KEYCHAIN_PATH="${3:-}"

SPARKLE_DIR="$APP_PATH/Contents/Frameworks/Sparkle.framework"
SPARKLE_VERSIONED_DIR="$SPARKLE_DIR/Versions/B"

fail() {
    echo "error: $1" >&2
    exit 1
}

CODESIGN_ARGS=(--force --sign "$IDENTITY" --options runtime)
if [ "$IDENTITY" = "-" ]; then
    # アドホック署名はタイムスタンプサーバーへ問い合わせられない。
    CODESIGN_ARGS+=(--timestamp=none)
else
    CODESIGN_ARGS+=(--timestamp)
fi
if [ -n "$KEYCHAIN_PATH" ]; then
    CODESIGN_ARGS+=(--keychain "$KEYCHAIN_PATH")
fi

# 拡張属性が残っていると codesign が "detritus not allowed" で失敗する。
xattr -cr "$APP_PATH"

codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_VERSIONED_DIR/XPCServices/Installer.xpc"
codesign "${CODESIGN_ARGS[@]}" --preserve-metadata=entitlements "$SPARKLE_VERSIONED_DIR/XPCServices/Downloader.xpc"
codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_VERSIONED_DIR/Autoupdate"
codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_VERSIONED_DIR/Updater.app"
codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_DIR"
# アプリの entitlements は Xcode が $(PRODUCT_BUNDLE_IDENTIFIER) を展開して署名に入れたものを保つ。
codesign "${CODESIGN_ARGS[@]}" --preserve-metadata=entitlements "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw -o - "$APP_PATH/Contents/Info.plist")"
[ -n "$BUNDLE_ID" ] || fail "CFBundleIdentifier is empty"

# plutil のキーパスは "." を区切りとして扱うため、キーに "." を含む entitlements は JSON にして調べる。
ENTITLEMENTS_JSON="$(codesign -d --entitlements - --xml "$APP_PATH" | plutil -convert json -o - -)" \
    || fail "could not read entitlements from $APP_PATH"

jq -e '."com.apple.security.app-sandbox" == true' <<<"$ENTITLEMENTS_JSON" >/dev/null \
    || fail "com.apple.security.app-sandbox must be true"
jq -e 'has("com.apple.security.get-task-allow") | not' <<<"$ENTITLEMENTS_JSON" >/dev/null \
    || fail "com.apple.security.get-task-allow must not be present"

# Sparkle の Installer サービスは <bundle id>-spks と -spki の mach-lookup を要求する。
for SERVICE in "$BUNDLE_ID-spks" "$BUNDLE_ID-spki"; do
    jq -e --arg service "$SERVICE" \
        '(."com.apple.security.temporary-exception.mach-lookup.global-name" // []) | index($service) != null' \
        <<<"$ENTITLEMENTS_JSON" >/dev/null \
        || fail "mach-lookup exception for $SERVICE is missing"
done

echo "Signed and verified: $APP_PATH"
