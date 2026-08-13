#!/bin/bash
# Create Logger-TXT.app bundle for distribution

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")/.."

APP_NAME="Logger-TXT"
BUNDLE_NAME="$APP_NAME.app"
BUILD_DIR=".build/release"
APP_VERSION="${VERSION:-2.0.0}"
# Overridable so an isolated test bundle can be built with its own preferences
# domain, well away from the real com.logger-txt.app.
BUNDLE_ID="${BUNDLE_ID:-com.logger-txt.app}"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building Logger-TXT v$APP_VERSION for release..."
swift build -c release

# Ask the toolchain where it put things rather than assuming the triple
# directory, so this works on any architecture and any CI runner.
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "Creating app bundle..."

# Clean up any existing bundle
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BIN_DIR/LoggerTXT" "$MACOS_DIR/"

# Copy SwiftPM resource bundles (e.g. KeyboardShortcuts_KeyboardShortcuts.bundle).
#
# SwiftPM's generated Bundle.module accessor probes
# Bundle.main.bundleURL/<name>.bundle, and for an .app that is the .app
# directory itself — not Contents/Resources. It hard-traps when the bundle is
# missing, so an app without these compiles and launches fine and then dies the
# first time a dependency reads a localized string. See docs/adr/010.
#
# The real payload goes in Contents/Resources, which is the conventional home
# and the only part of a bundle codesign seals; the root entry is a relative
# symlink to it, which is what the accessor actually reads. Globbing rather
# than naming dependencies means a future package with resources needs no edit
# here.
for resource_bundle in "$BIN_DIR"/*.bundle; do
    bundle_basename="$(basename "$resource_bundle")"
    echo "  bundling $bundle_basename"
    ditto "$resource_bundle" "$RESOURCES_DIR/$bundle_basename"
    ln -s "Contents/Resources/$bundle_basename" "$BUNDLE_DIR/$bundle_basename"
done

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
    <string>$BUNDLE_ID</string>
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

# Never hand back a bundle that would trap at runtime.
echo ""
./Scripts/verify-app-bundle.sh "$BUNDLE_DIR" --bin-dir "$BIN_DIR"

echo ""
echo "Bundle created at: $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  rm -rf /Applications/$BUNDLE_NAME && ditto \"$BUNDLE_DIR\" \"/Applications/$BUNDLE_NAME\""
echo ""
echo "To open directly:"
echo "  open \"$BUNDLE_DIR\""
