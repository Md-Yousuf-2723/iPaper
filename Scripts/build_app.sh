#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

VERSION="1.0.2"
BUILD_NUM="3"

echo "=== Building iPaper (Release v${VERSION}) ==="
swift build -c release

BIN_DIR=$(swift build -c release --show-bin-path)
BIN_PATH="$BIN_DIR/iPaper"

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: Binary not found at $BIN_PATH"
    exit 1
fi

APP_NAME="iPaper"
APP_BUNDLE="build/${APP_NAME}.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "=== Packaging ${APP_NAME}.app ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

cp "$BIN_PATH" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

# Copy Icon and Resources
if [ -f "Assets/AppIcon.icns" ]; then
    cp "Assets/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
if [ -f "Assets/logo_app.png" ]; then
    cp "Assets/logo_app.png" "$RESOURCES/logo_app.png"
fi

# Copy any SPM bundle resources
for bundle in "$BIN_DIR"/*.bundle; do
    if [ -d "$bundle" ]; then
        echo "Copying resource bundle: $(basename "$bundle")"
        cp -R "$bundle" "$RESOURCES/"
    fi
done

# Write Info.plist
cat << PLIST > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>iPaper</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.yousuf.iPaper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>iPaper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUM}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Md Yousuf. All rights reserved.</string>
</dict>
</plist>
PLIST

echo "=== Code Signing ${APP_BUNDLE} ==="
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "=== Build and packaging complete: ${APP_BUNDLE} ==="
