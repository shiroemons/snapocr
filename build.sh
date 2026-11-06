#!/bin/bash
set -euo pipefail

APP_NAME="SnapOCR Dev"
SCHEME="SnapOCR"
DEST="platform=macOS"
CONFIG="Debug"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${SCRIPT_DIR}/${APP_NAME}.app"
# 既定の DerivedData はプロジェクト名とハッシュを含むパスになるので、成果物の場所を固定する。
DERIVED_DATA_PATH="${SCRIPT_DIR}/build"
BUILT_APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIG}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
xcodebuild build \
    -project "${SCRIPT_DIR}/SnapOCR.xcodeproj" \
    -scheme "${SCHEME}" \
    -destination "${DEST}" \
    -configuration "${CONFIG}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -quiet

if [ ! -d "${BUILT_APP_PATH}" ]; then
    echo "Error: Built app not found at ${BUILT_APP_PATH}" >&2
    exit 1
fi

# Stop running instance
pkill -x "${APP_NAME}" 2>/dev/null && sleep 1 || true

# Copy to project root
rm -rf "${APP_PATH}"
cp -R "${BUILT_APP_PATH}" "${APP_PATH}"

echo "Installed: ${APP_PATH}"
