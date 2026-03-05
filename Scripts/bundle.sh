#!/bin/bash
# Create Logger-TXT.app bundle for distribution

set -e

cd "$(dirname "$0")/.."

APP_NAME="Logger-TXT"
BUNDLE_NAME="$APP_NAME.app"
BUILD_DIR=".build/release"
APP_VERSION="${VERSION:-2.0.0}"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building Logger-TXT v$APP_VERSION for release..."
swift build -c release

echo "Creating app bundle..."

# Clean up any existing bundle
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/LoggerTXT" "$MACOS_DIR/"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LoggerTXT</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.logger-txt.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Logger-TXT</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo ""
echo "Bundle created at: $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  cp -r \"$BUNDLE_DIR\" /Applications/"
echo ""
echo "To open directly:"
echo "  open \"$BUNDLE_DIR\""
