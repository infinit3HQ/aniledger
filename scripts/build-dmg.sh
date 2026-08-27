#!/bin/bash

# ==============================================================================
# DMG Creation Script for AniLedger (Exact Original Proven Flow)
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AniLedger"
SCHEME_NAME="AniLedger"
CONFIGURATION="Release"
BUILD_DIR="${PROJECT_DIR}/build"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"
OUTPUT_DIR="${PROJECT_DIR}/dist"
BACKGROUND_IMAGE="${PROJECT_DIR}/scripts/assets/Install.jpg"

VERSION=$(grep -m1 "MARKETING_VERSION" "${PROJECT_DIR}/AniLedger.xcodeproj/project.pbxproj" | sed -e 's/[^0-9.]//g')
if [ -z "${VERSION}" ]; then
    VERSION="0.4.0"
fi

DMG_NAME="AniLedger-${VERSION}"
VOLUME_NAME="AniLedger"
DMG_SIZE="60m"
TEMP_DMG_DIR="${BUILD_DIR}/dmg_temp"

echo "🔨 Building ${APP_NAME} (${CONFIGURATION} mode)..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild -project "${PROJECT_DIR}/AniLedger.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -destination 'platform=macOS' \
    -derivedDataPath "${DERIVED_DATA_DIR}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build | xcpretty 2>/dev/null || true

APP_PATH="${DERIVED_DATA_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Error: App build failed, ${APP_PATH} not found!"
    exit 1
fi

echo "📦 Copying ${APP_NAME}.app..."
cp -R "${APP_PATH}" "${OUTPUT_DIR}/"

# Clean up temporary staging
rm -rf "${TEMP_DMG_DIR}"
mkdir -p "${TEMP_DMG_DIR}"

# Staging contains ONLY App and Applications symlink
cp -R "${APP_PATH}" "${TEMP_DMG_DIR}/"
ln -s /Applications "${TEMP_DMG_DIR}/Applications"

# Create temporary DMG
echo "💿 Creating temporary DMG..."
TEMP_DMG="${BUILD_DIR}/temp-${DMG_NAME}.dmg"
rm -f "${TEMP_DMG}"
hdiutil create -srcfolder "${TEMP_DMG_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size "${DMG_SIZE}" "${TEMP_DMG}"

# Mount the temporary DMG
echo "📂 Mounting temporary DMG..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}" | grep -o '/Volumes/.*' | head -n1)

# Wait a moment for mount
sleep 2

# Copy background image into mounted volume
if [ -f "${BACKGROUND_IMAGE}" ]; then
    echo "🎨 Adding background image..."
    mkdir -p "${MOUNT_DIR}/.background"
    cp "${BACKGROUND_IMAGE}" "${MOUNT_DIR}/.background/Install.jpg"
fi

# Set the DMG window appearance using exact original AppleScript
echo "✨ Configuring DMG appearance..."
osascript <<EOD
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 900, 550}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:Install.jpg"

        -- Position the app icon and Applications link
        set position of item "${APP_NAME}.app" of container window to {200, 225}
        set position of item "Applications" of container window to {600, 225}

        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOD

# Ensure changes are written
sync

# Unmount the temporary DMG
echo "💾 Finalizing DMG..."
hdiutil detach "${MOUNT_DIR}"

# Convert to compressed, read-only DMG
FINAL_DMG="${OUTPUT_DIR}/${DMG_NAME}.dmg"
INSTALLER_DMG="${OUTPUT_DIR}/AniLedger-Installer.dmg"

echo "🗜️ Compressing DMG..."
rm -f "${FINAL_DMG}" "${INSTALLER_DMG}"
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"
cp "${FINAL_DMG}" "${INSTALLER_DMG}"

# Clean up
echo "🧹 Cleaning up..."
rm -f "${TEMP_DMG}"
rm -rf "${TEMP_DMG_DIR}"

echo "✅ DMG created successfully: ${FINAL_DMG}"
