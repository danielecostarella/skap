#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Skap"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

if [[ ! -d "$SOURCE_APP" ]]; then
	"$ROOT_DIR/scripts/package-app.sh"
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

echo "Installed $TARGET_APP"
