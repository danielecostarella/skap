#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Skap"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION" --product "$APP_NAME"

BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Packaging/Skap.app/Contents/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Packaging/Skap.app/Contents/PkgInfo" "$CONTENTS_DIR/PkgInfo"

if [[ -f "$ROOT_DIR/Packaging/Skap.app/Contents/Resources/AppIcon.icns" ]]; then
	cp "$ROOT_DIR/Packaging/Skap.app/Contents/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

codesign --force --sign - "$APP_BUNDLE"

echo "Created $APP_BUNDLE"
