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

echo "▸ Assembling ${BUNDLE}…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"

echo "▸ Ad-hoc code signing…"
codesign --force --deep --sign - "$BUNDLE"

echo "✓ Built ${BUNDLE}"
echo "  Run:      open ${BUNDLE}"
echo "  Install:  cp -R ${BUNDLE} /Applications/"
