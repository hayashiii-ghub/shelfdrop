#!/usr/bin/env bash

SHELFDROP_APP_NAME="DopaGak"
SHELFDROP_DISPLAY_NAME="DOPA-GAK!"
SHELFDROP_BUNDLE_ID="work.hayashigoto.dopagak"
SHELFDROP_MIN_SYSTEM_VERSION="14.0"

shelfdrop_copy_bundle_resources() {
  local root_dir="$1"
  local resources_dir="$2"

  cp "$root_dir/Assets/DopaGak.icns" "$resources_dir/DopaGak.icns"
  cp "$root_dir/Assets/MenuBarTemplate.png" "$resources_dir/MenuBarTemplate.png"
  cp "$root_dir/Assets/PochittoSkeletonPlate.png" "$resources_dir/PochittoSkeletonPlate.png"
  cp "$root_dir/Assets/KurukuruChassisFront.png" "$resources_dir/KurukuruChassisFront.png"
  cp "$root_dir/Assets/KurukuruWheelRing.png" "$resources_dir/KurukuruWheelRing.png"
  cp "$root_dir/Assets/KurukuruCenterButton.png" "$resources_dir/KurukuruCenterButton.png"
}

shelfdrop_write_info_plist() {
  local info_plist="$1"
  local app_version="$2"

  cat >"$info_plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$SHELFDROP_APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$SHELFDROP_BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$SHELFDROP_APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$SHELFDROP_DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>DopaGak.icns</string>
  <key>CFBundleShortVersionString</key>
  <string>$app_version</string>
  <key>CFBundleVersion</key>
  <string>$app_version</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$SHELFDROP_MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Finder access is used to add your selected files to the shelf.</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}
