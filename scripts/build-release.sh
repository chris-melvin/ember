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
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/$DMG_NAME"

rm -rf "$DMG_DIR"

echo ""
echo "==> Done! DMG ready at:"
echo "    $BUILD_DIR/$DMG_NAME"
echo ""
echo "To install: open the DMG and drag Ember to Applications."
echo "To distribute: upload $BUILD_DIR/$DMG_NAME to a GitHub Release."
