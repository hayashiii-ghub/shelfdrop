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
DMG_STAGING_DIR="$STAGING_DIR/dmg"
DMG_MOUNT_DIR="$STAGING_DIR/dmg-mount"
DMG_RW_PATH="$STAGING_DIR/$APP_NAME-rw.dmg"
APP_BUNDLE="$PACKAGE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/ShelfDrop.icns"
MENU_BAR_ICON="$ROOT_DIR/Assets/MenuBarTemplate.png"
ZIP_PATH="$DIST_DIR/$APP_NAME-macos.zip"
DMG_PATH="$DIST_DIR/$APP_NAME-macos.dmg"
SWIFTPM_CACHE_DIR="$ROOT_DIR/.build/cache"
VALIDATION_DIR="$STAGING_DIR/validation"

cleanup() {
  hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

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

rm -rf "$DIST_PACKAGE_DIR" "$ZIP_PATH" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/ShelfDrop.icns"
cp "$MENU_BAR_ICON" "$APP_RESOURCES/MenuBarTemplate.png"
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
  <key>CFBundleIconFile</key>
  <string>ShelfDrop.icns</string>
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
mkdir -p "$VALIDATION_DIR"
ditto -x -k "$ZIP_PATH" "$VALIDATION_DIR"
codesign --verify --deep --strict "$VALIDATION_DIR/$APP_NAME.app"

mkdir -p "$DIST_PACKAGE_DIR"
COPYFILE_DISABLE=1 ditto --norsrc --noextattr --noqtn --noacl \
  "$APP_BUNDLE" "$DIST_PACKAGE_DIR/$APP_NAME.app"
xattr -cr "$DIST_PACKAGE_DIR/$APP_NAME.app" 2>/dev/null || true
codesign --force --sign - "$DIST_PACKAGE_DIR/$APP_NAME.app"
codesign --verify --deep --strict "$DIST_PACKAGE_DIR/$APP_NAME.app"

mkdir -p "$DMG_STAGING_DIR"
COPYFILE_DISABLE=1 ditto --norsrc --noextattr --noqtn --noacl \
  "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_NAME.app"
xattr -cr "$DMG_STAGING_DIR/$APP_NAME.app" 2>/dev/null || true
codesign --force --sign - "$DMG_STAGING_DIR/$APP_NAME.app"
codesign --verify --deep --strict "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -fs HFS+ \
  -format UDRW \
  -ov \
  "$DMG_RW_PATH"

mkdir -p "$DMG_MOUNT_DIR"
hdiutil attach -readwrite -noverify -noautoopen -mountpoint "$DMG_MOUNT_DIR" "$DMG_RW_PATH" >/dev/null

osascript <<APPLESCRIPT
tell application "Finder"
  set dmgFolderAlias to POSIX file "$DMG_MOUNT_DIR" as alias
  tell folder dmgFolderAlias
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 700, 440}
    set icon size of icon view options of container window to 96
    set text size of icon view options of container window to 16
    set position of item "$APP_NAME.app" to {180, 150}
    set position of item "Applications" to {420, 150}
    update without registering applications
    close container window
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DMG_MOUNT_DIR" >/dev/null

hdiutil convert "$DMG_RW_PATH" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH"
hdiutil verify "$DMG_PATH"

hdiutil attach -nobrowse -readonly -mountpoint "$DMG_MOUNT_DIR" "$DMG_PATH" >/dev/null
test -d "$DMG_MOUNT_DIR/$APP_NAME.app"
test -L "$DMG_MOUNT_DIR/Applications"
codesign --verify --deep --strict "$DMG_MOUNT_DIR/$APP_NAME.app"
hdiutil detach "$DMG_MOUNT_DIR" >/dev/null

echo "$ZIP_PATH"
echo "$DMG_PATH"
