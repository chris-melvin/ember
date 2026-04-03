#!/bin/bash
set -euo pipefail

# Build a release .dmg for Ember
# Usage: ./scripts/build-release.sh [version]
# Example: ./scripts/build-release.sh 0.1.0

VERSION="${1:-$(grep MARKETING_VERSION project.yml | head -1 | sed 's/.*"\(.*\)"/\1/')}"
APP_NAME="Ember"
SCHEME="Ember"
PROJECT="Ember.xcodeproj"
BUILD_DIR="build/release"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "==> Building ${APP_NAME} v${VERSION} (Release)"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Regenerate Xcode project to pick up any changes
if command -v xcodegen &> /dev/null; then
    echo "==> Regenerating Xcode project..."
    xcodegen generate 2>&1 | tail -1
fi

# Build release
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/derived" \
    MARKETING_VERSION="$VERSION" \
    clean build 2>&1 | tail -5

APP_PATH="$BUILD_DIR/derived/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Build failed — .app not found at $APP_PATH"
    exit 1
fi

echo "==> Build succeeded: $APP_PATH"

# Create DMG
echo "==> Creating DMG..."
DMG_DIR="$BUILD_DIR/dmg-staging"
DMG_TEMP="$BUILD_DIR/${APP_NAME}-temp.dmg"
DMG_FINAL="$BUILD_DIR/$DMG_NAME"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create a read-write DMG (without hidden folders in the source)
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    -fs HFS+ \
    "$DMG_TEMP" 2>/dev/null

rm -rf "$DMG_DIR"

# Mount and style
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP")
DEVICE=$(echo "$MOUNT_OUTPUT" | head -1 | awk '{print $1}')
MOUNT_DIR="/Volumes/$APP_NAME"

echo "==> Styling DMG window..."

# Remove .fseventsd that macOS auto-creates
rm -rf "$MOUNT_DIR/.fseventsd"

# Use AppleScript to style the Finder window
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 200, 680, 460}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 104
        set text size of theViewOptions to 14
        set position of item "${APP_NAME}.app" of container window to {120, 130}
        set position of item "Applications" of container window to {360, 130}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

# Make sure .fseventsd doesn't come back, and hide any dotfiles
rm -rf "$MOUNT_DIR/.fseventsd"
mkdir "$MOUNT_DIR/.fseventsd"
touch "$MOUNT_DIR/.fseventsd/no_log"

# Set Finder window attributes via .DS_Store (already set by AppleScript above)
# Hide hidden files on the volume
SetFile -a V "$MOUNT_DIR/.fseventsd" 2>/dev/null || true

sync
hdiutil detach "$DEVICE" 2>/dev/null || hdiutil detach "$MOUNT_DIR" 2>/dev/null || true

# Convert to compressed read-only DMG
rm -f "$DMG_FINAL"
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL" 2>/dev/null

rm -f "$DMG_TEMP"

echo ""
echo "==> Done! DMG ready at:"
echo "    $DMG_FINAL"
echo ""
echo "To install: open the DMG and drag Ember to Applications."
echo "To distribute: upload $DMG_FINAL to a GitHub Release."
