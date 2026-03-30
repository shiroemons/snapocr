#!/usr/bin/env bash
set -euo pipefail

# Usage: create-dmg.sh <APP_PATH> <APP_NAME> <OUTPUT_DMG_PATH>
APP_PATH="${1:?APP_PATH is required}"
APP_NAME="${2:?APP_NAME is required}"
OUTPUT_DMG_PATH="${3:?OUTPUT_DMG_PATH is required}"

VOLUME_NAME="$APP_NAME"
MOUNT_POINT="/Volumes/$VOLUME_NAME"
RW_DMG="${OUTPUT_DMG_PATH%.dmg}-rw.dmg"

cleanup() {
    if mount | grep -q "$MOUNT_POINT"; then
        hdiutil detach "$MOUNT_POINT" -force 2>/dev/null || true
    fi
    rm -f "$RW_DMG"
}
trap cleanup EXIT

echo "Creating writable DMG..."
hdiutil create -size 200m -fs HFS+ -volname "$VOLUME_NAME" "$RW_DMG"
hdiutil attach "$RW_DMG" -mountpoint "$MOUNT_POINT"

echo "Copying app bundle..."
cp -R "$APP_PATH" "$MOUNT_POINT/"

echo "Creating Finder alias to /Applications..."
osascript -e "tell application \"Finder\" to make alias file to POSIX file \"/Applications\" at POSIX file \"$MOUNT_POINT\" with properties {name:\"Applications\"}"

echo "Setting Applications folder icon via NSWorkspace..."
ICON_SWIFT=$(mktemp /tmp/set-icon-XXXXXX.swift)
cat > "$ICON_SWIFT" <<'SWIFT'
import AppKit

let appName = CommandLine.arguments[1]
let mountPoint = "/Volumes/\(appName)"
let target = "\(mountPoint)/Applications"

guard let icon = NSWorkspace.shared.icon(forFile: "/Applications") as NSImage? else {
    fputs("Failed to get /Applications icon\n", stderr)
    exit(1)
}

let success = NSWorkspace.shared.setIcon(icon, forFile: target, options: [])
if !success {
    fputs("Failed to set icon on \(target)\n", stderr)
    exit(1)
}
print("Icon set successfully on \(target)")
SWIFT

swift "$ICON_SWIFT" "$APP_NAME"
rm -f "$ICON_SWIFT"

echo "Configuring DMG window appearance via AppleScript..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 800, 520}
        set icon size of icon view options of container window to 100
        set position of item "$APP_NAME.app" of container window to {175, 190}
        set position of item "Applications" of container window to {425, 190}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

echo "Waiting for .DS_Store to be written..."
sleep 2

echo "Setting volume icon to app icon..."
ICON_FILE="$MOUNT_POINT/$APP_NAME.app/Contents/Resources/AppIcon.icns"
if [ ! -f "$ICON_FILE" ]; then
    ICON_NAME=$(defaults read "$MOUNT_POINT/$APP_NAME.app/Contents/Info" CFBundleIconFile)
    ICON_NAME="${ICON_NAME%.icns}.icns"
    ICON_FILE="$MOUNT_POINT/$APP_NAME.app/Contents/Resources/$ICON_NAME"
fi
cp "$ICON_FILE" "$MOUNT_POINT/.VolumeIcon.icns"
SetFile -a C "$MOUNT_POINT"

echo "Detaching DMG..."
hdiutil detach "$MOUNT_POINT"

echo "Converting to compressed DMG..."
hdiutil convert "$RW_DMG" -format UDZO -o "$OUTPUT_DMG_PATH"

echo "Setting app icon on DMG file..."
APP_ICON_FILE="$APP_PATH/Contents/Resources/AppIcon.icns"
if [ ! -f "$APP_ICON_FILE" ]; then
    APP_ICON_NAME=$(defaults read "$APP_PATH/Contents/Info" CFBundleIconFile)
    APP_ICON_NAME="${APP_ICON_NAME%.icns}.icns"
    APP_ICON_FILE="$APP_PATH/Contents/Resources/$APP_ICON_NAME"
fi
DMG_ICON_SWIFT=$(mktemp /tmp/set-dmg-icon-XXXXXX.swift)
cat > "$DMG_ICON_SWIFT" <<'SWIFT'
import AppKit

let dmgPath = CommandLine.arguments[1]
let iconPath = CommandLine.arguments[2]

guard let icon = NSImage(contentsOfFile: iconPath) else {
    fputs("Failed to load icon from \(iconPath)\n", stderr)
    exit(1)
}

let result = NSWorkspace.shared.setIcon(icon, forFile: dmgPath)
exit(result ? 0 : 1)
SWIFT

swift "$DMG_ICON_SWIFT" "$OUTPUT_DMG_PATH" "$APP_ICON_FILE"
rm -f "$DMG_ICON_SWIFT"

echo "DMG created: $OUTPUT_DMG_PATH"
