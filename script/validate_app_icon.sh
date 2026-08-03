#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PNG="$ROOT_DIR/Assets/DopaGak.png"
SMALL_SOURCE_PNG="$ROOT_DIR/Assets/DopaGakIconSmall.png"
ICONSET_DIR="$ROOT_DIR/Assets/DopaGak.iconset"
OUTPUT_ICNS="$ROOT_DIR/Assets/DopaGak.icns"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT_DIR/.build/module-cache}"

expected=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)

for entry in "${expected[@]}"; do
  file="${entry%%:*}"
  pixels="${entry##*:}"
  path="$ICONSET_DIR/$file"
  test -f "$path"
  width="$(sips -g pixelWidth "$path" | awk '/pixelWidth/ { print $2 }')"
  height="$(sips -g pixelHeight "$path" | awk '/pixelHeight/ { print $2 }')"
  has_alpha="$(sips -g hasAlpha "$path" | awk '/hasAlpha/ { print $2 }')"
  if [[ "$width" != "$pixels" || "$height" != "$pixels" || "$has_alpha" != "yes" ]]; then
    echo "Invalid icon representation: $file" >&2
    exit 1
  fi
done

test -s "$OUTPUT_ICNS"

swift "$ROOT_DIR/script/validate_app_icon.swift" "$SOURCE_PNG"
swift "$ROOT_DIR/script/validate_app_icon.swift" "$SMALL_SOURCE_PNG"
echo "App icon validation passed"
