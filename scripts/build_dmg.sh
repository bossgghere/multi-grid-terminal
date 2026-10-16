#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

echo "==> Packaging GridTerm.app..."
./scripts/package_app.sh

APP_NAME="GridTerm"
APP_BUNDLE="${PROJECT_DIR}/${APP_NAME}.app"
DIST_DIR="${PROJECT_DIR}/dist"
STAGING_DIR="${DIST_DIR}/staging"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

echo "==> Preparing DMG staging environment..."
rm -rf "${DIST_DIR}"
mkdir -p "${STAGING_DIR}"

echo "==> Copying ${APP_NAME}.app to DMG staging..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/${APP_NAME}.app"

echo "==> Creating /Applications symlink for drag-and-drop installer..."
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Generating compressed DMG using hdiutil..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo "==> Verifying DMG integrity..."
hdiutil verify "${DMG_PATH}"

# Clean up staging directory
rm -rf "${STAGING_DIR}"

DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
echo "=========================================================="
echo "✨ Successfully built ${APP_NAME}.dmg (${DMG_SIZE})"
echo "📁 Output: ${DMG_PATH}"
echo "🚀 Ready to distribute to users or upload to GitHub Releases!"
echo "=========================================================="
