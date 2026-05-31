#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")}"
APP_BUNDLE="$ROOT_DIR/dist/Skap.app"
OUTPUT="$ROOT_DIR/dist/Skap-$VERSION.dmg"
BG_IMAGE="$ROOT_DIR/dist/dmg-background.png"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "error: $APP_BUNDLE not found — run scripts/package-app.sh first" >&2
    exit 1
fi

command -v create-dmg >/dev/null 2>&1 || { echo "error: create-dmg not found (brew install create-dmg)"; exit 1; }

# Generate background image
echo "Generating DMG background…"
swift "$ROOT_DIR/scripts/generate-dmg-background.swift" "$BG_IMAGE"

rm -f "$OUTPUT"
echo "Creating DMG…"
create-dmg \
    --volname "Skap $VERSION" \
    --background "$BG_IMAGE" \
    --window-pos  200 140 \
    --window-size 660 400 \
    --icon-size   120 \
    --icon        "Skap.app" 165 200 \
    --hide-extension "Skap.app" \
    --app-drop-link  495 200 \
    "$OUTPUT" \
    "$APP_BUNDLE"

rm -f "$BG_IMAGE"
echo "Created $OUTPUT"
