#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ShelfDrop"
BUNDLE_ID="work.hayashigoto.ShelfDrop"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/script/version.sh"

APP_VERSION="$(resolve_shelfdrop_version "$ROOT_DIR")"
DIST_DIR="$ROOT_DIR/dist"
DIST_PACKAGE_DIR="$DIST_DIR/package"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ShelfDrop-package.XXXXXX")"
PACKAGE_DIR="$STAGING_DIR/package"
APP_BUNDLE="$PACKAGE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME-macos.zip"
SWIFTPM_CACHE_DIR="$ROOT_DIR/.build/cache"

trap 'rm -rf "$STAGING_DIR"' EXIT

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"

cd "$ROOT_DIR"

DEVELOPER_DIR_PATH="$(xcode-select -p 2>/dev/null || true)"
XCBUILD_PATH="$(dirname "$DEVELOPER_DIR_PATH")/SharedFrameworks/XCBuild.framework/Versions/A/Support/xcbuild"
UNIVERSAL_MODE="${SHELFDROP_UNIVERSAL:-auto}"

if [[ "$UNIVERSAL_MODE" == "1" || "$UNIVERSAL_MODE" == "true" ]]; then
  SWIFT_BUILD_FLAGS=(-c release --arch arm64 --arch x86_64 --cache-path "$SWIFTPM_CACHE_DIR")
  BUILD_KIND="universal"
elif [[ -x "$XCBUILD_PATH" ]]; then
  SWIFT_BUILD_FLAGS=(-c release --arch arm64 --arch x86_64 --cache-path "$SWIFTPM_CACHE_DIR")
  BUILD_KIND="universal"
else
  SWIFT_BUILD_FLAGS=(-c release --cache-path "$SWIFTPM_CACHE_DIR")
  BUILD_KIND="host-architecture"
fi

echo "Building $BUILD_KIND release..."
swift build "${SWIFT_BUILD_FLAGS[@]}"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_FLAGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$DIST_PACKAGE_DIR" "$ZIP_PATH"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>ShelfDrop uses Finder access to add your selected files to the shelf.</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

# Strip Finder/resource metadata before signing so strict validation and
# distribution zips do not contain AppleDouble files or disallowed xattrs.
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

# Ad hoc signing keeps the bundle structurally signed without requiring
# an Apple Developer ID. It is still not notarized, so Gatekeeper will warn.
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

mkdir -p "$DIST_DIR"
COPYFILE_DISABLE=1 ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$APP_BUNDLE" "$ZIP_PATH"

mkdir -p "$DIST_PACKAGE_DIR"
COPYFILE_DISABLE=1 ditto --norsrc --noextattr --noqtn --noacl \
  "$APP_BUNDLE" "$DIST_PACKAGE_DIR/$APP_NAME.app"

echo "$ZIP_PATH"
