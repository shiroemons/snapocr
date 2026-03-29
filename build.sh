#!/bin/bash
set -euo pipefail

APP_NAME="SnapOCR Dev"
SCHEME="SnapOCR"
DEST="platform=macOS"
CONFIG="Debug"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${SCRIPT_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
xcodebuild build \
    -scheme "${SCHEME}" \
    -destination "${DEST}" \
    -configuration "${CONFIG}" \
    -quiet

# Find the latest DerivedData build
DERIVED_APP=$(find ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*/Build/Products/${CONFIG}/${APP_NAME}.app -maxdepth 0 -type d 2>/dev/null | head -1)

if [ -z "${DERIVED_APP}" ]; then
    echo "Error: Built app not found in DerivedData" >&2
    exit 1
fi

# Stop running instance
pkill -x "${APP_NAME}" 2>/dev/null && sleep 1 || true

# Copy to project root
rm -rf "${APP_PATH}"
cp -R "${DERIVED_APP}" "${APP_PATH}"

echo "Installed: ${APP_PATH}"
