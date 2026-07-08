#!/bin/bash
# Builds pocket and assembles pocket.app (ad-hoc signed) into ./build.
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP_NAME="pocket"
BUNDLE="build/${APP_NAME}.app"

echo "▸ Compiling ($CONFIG)…"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)/${APP_NAME}"

echo "▸ Rendering app icon…"
swift Scripts/make-icon.swift build/AppIcon.icns || echo "  (icon generation skipped)"

echo "▸ Assembling ${BUNDLE}…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
[ -f build/AppIcon.icns ] && cp build/AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "▸ Ad-hoc code signing…"
codesign --force --deep --sign - "$BUNDLE"

echo "✓ Built ${BUNDLE}"
echo "  Run:      open ${BUNDLE}"
echo "  Install:  cp -R ${BUNDLE} /Applications/"
