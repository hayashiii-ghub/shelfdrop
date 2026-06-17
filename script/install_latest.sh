#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ShelfDrop"
ZIP_URL="https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.zip"
TMP_DIR="$(mktemp -d)"
ZIP_PATH="$TMP_DIR/$APP_NAME-macos.zip"
EXTRACT_DIR="$TMP_DIR/extract"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

choose_install_dir() {
  if [[ -n "${SHELFDROP_INSTALL_DIR:-}" ]]; then
    printf '%s\n' "$SHELFDROP_INSTALL_DIR"
    return
  fi

  if [[ -d "/Applications/$APP_NAME.app" ]]; then
    printf '%s\n' "/Applications"
    return
  fi

  if [[ -d "$HOME/Applications/$APP_NAME.app" ]]; then
    printf '%s\n' "$HOME/Applications"
    return
  fi

  if [[ -w "/Applications" ]]; then
    printf '%s\n' "/Applications"
    return
  fi

  printf '%s\n' "$HOME/Applications"
}

install_app() {
  local source_app="$1"
  local destination_app="$2"
  local install_dir
  install_dir="$(dirname "$destination_app")"

  if [[ -w "$install_dir" ]]; then
    rm -rf "$destination_app"
    ditto "$source_app" "$destination_app"
    xattr -dr com.apple.quarantine "$destination_app" 2>/dev/null || true
    return
  fi

  echo "Installing to $install_dir requires administrator permission."
  sudo rm -rf "$destination_app"
  sudo ditto "$source_app" "$destination_app"
  sudo xattr -dr com.apple.quarantine "$destination_app" 2>/dev/null || true
}

INSTALL_DIR="$(choose_install_dir)"
DESTINATION_APP="$INSTALL_DIR/$APP_NAME.app"

echo "Downloading latest $APP_NAME..."
curl -L --fail -A "Mozilla/5.0" -o "$ZIP_PATH" "$ZIP_URL"

mkdir -p "$EXTRACT_DIR"
ditto -x -k "$ZIP_PATH" "$EXTRACT_DIR"

SOURCE_APP="$EXTRACT_DIR/$APP_NAME.app"
if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Downloaded archive did not contain $APP_NAME.app" >&2
  exit 1
fi

if [[ "${SHELFDROP_SKIP_STOP:-0}" != "1" ]]; then
  echo "Stopping running $APP_NAME..."
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi

mkdir -p "$INSTALL_DIR"
echo "Installing to $DESTINATION_APP..."
install_app "$SOURCE_APP" "$DESTINATION_APP"

if [[ "${SHELFDROP_SKIP_OPEN:-0}" != "1" ]]; then
  open "$DESTINATION_APP"
fi

echo "Updated $APP_NAME at $DESTINATION_APP"
