#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PNG="$ROOT_DIR/Assets/DopaGak.png"
SMALL_SOURCE_PNG="$ROOT_DIR/Assets/DopaGakIconSmall.png"
ICONSET_DIR="$ROOT_DIR/Assets/DopaGak.iconset"
OUTPUT_ICNS="$ROOT_DIR/Assets/DopaGak.icns"

width="$(sips -g pixelWidth "$SOURCE_PNG" | awk '/pixelWidth/ { print $2 }')"
height="$(sips -g pixelHeight "$SOURCE_PNG" | awk '/pixelHeight/ { print $2 }')"
has_alpha="$(sips -g hasAlpha "$SOURCE_PNG" | awk '/hasAlpha/ { print $2 }')"

small_width="$(sips -g pixelWidth "$SMALL_SOURCE_PNG" | awk '/pixelWidth/ { print $2 }')"
small_height="$(sips -g pixelHeight "$SMALL_SOURCE_PNG" | awk '/pixelHeight/ { print $2 }')"
small_has_alpha="$(sips -g hasAlpha "$SMALL_SOURCE_PNG" | awk '/hasAlpha/ { print $2 }')"

if [[ "$width" != "1024" || "$height" != "1024" || "$has_alpha" != "yes" \
    || "$small_width" != "1024" || "$small_height" != "1024" || "$small_has_alpha" != "yes" ]]; then
  echo "DopaGak.png must be a 1024x1024 RGBA PNG" >&2
  exit 1
fi

mkdir -p "$ICONSET_DIR"

make_rep() {
  local pixels="$1"
  local filename="$2"
  local source="${3:-$SOURCE_PNG}"
  sips -z "$pixels" "$pixels" "$source" --out "$ICONSET_DIR/$filename" >/dev/null
}

make_rep 16 icon_16x16.png "$SMALL_SOURCE_PNG"
make_rep 32 icon_16x16@2x.png "$SMALL_SOURCE_PNG"
make_rep 32 icon_32x32.png "$SMALL_SOURCE_PNG"
make_rep 64 icon_32x32@2x.png "$SMALL_SOURCE_PNG"
make_rep 128 icon_128x128.png
make_rep 256 icon_128x128@2x.png
make_rep 256 icon_256x256.png
make_rep 512 icon_256x256@2x.png
make_rep 512 icon_512x512.png
make_rep 1024 icon_512x512@2x.png

iconutil --convert icns --output "$OUTPUT_ICNS" "$ICONSET_DIR"
"$ROOT_DIR/script/validate_app_icon.sh"

echo "Generated $OUTPUT_ICNS"
