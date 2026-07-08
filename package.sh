#!/bin/bash
# Builds a shareable, drag-to-install pocket.dmg into ./dist.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh release

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" build/pocket.app/Contents/Info.plist)
DMG="dist/pocket-${VERSION}.dmg"

echo "▸ Staging disk image…"
STAGE=$(mktemp -d)
cp -R build/pocket.app "$STAGE/pocket.app"
ln -s /Applications "$STAGE/Applications"

echo "▸ Building ${DMG}…"
mkdir -p dist
rm -f "$DMG"
hdiutil create -volname "pocket ${VERSION}" -srcfolder "$STAGE" \
    -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "✓ ${DMG}"
echo "  Share this file. To install: open it and drag pocket into Applications."
