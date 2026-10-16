#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

echo "==> Building GridTerm in Release mode..."
swift build -c release

APP_NAME="GridTerm"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Creating .app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "==> Copying binary..."
cp -f ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "==> Copying icon..."
if [ -f "AppIcon.icns" ]; then
    cp -f "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "==> Creating Info.plist..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GridTerm</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.gridterm.GridTerm</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GridTerm</string>
    <key>CFBundleDisplayName</key>
    <string>GridTerm</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Creating PkgInfo..."
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "==> Signing app bundle with ad-hoc signature..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Installing into /Applications..."
rm -rf "/Applications/${APP_NAME}.app"
cp -R "${APP_BUNDLE}" "/Applications/${APP_NAME}.app"

echo "==> Successfully installed ${APP_NAME}.app into /Applications!"
