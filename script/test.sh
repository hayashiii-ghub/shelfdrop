#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLT_FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
CLT_DEVELOPER_LIB="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
SWIFT_TEST_FLAGS=()

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/module-cache}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT_DIR/.build/module-cache}"

if [[ "$(xcode-select -p 2>/dev/null || true)" == "/Library/Developer/CommandLineTools" \
    && -d "$CLT_FRAMEWORKS/Testing.framework" \
    && -f "$CLT_DEVELOPER_LIB/lib_TestingInterop.dylib" ]]; then
  SWIFT_TEST_FLAGS=(
    -Xswiftc -F -Xswiftc "$CLT_FRAMEWORKS"
    -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays
    -Xlinker -F -Xlinker "$CLT_FRAMEWORKS"
    -Xlinker -rpath -Xlinker "$CLT_FRAMEWORKS"
    -Xlinker -rpath -Xlinker "$CLT_DEVELOPER_LIB"
  )
  export DYLD_LIBRARY_PATH="$CLT_DEVELOPER_LIB${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
fi

cd "$ROOT_DIR"
if (( ${#SWIFT_TEST_FLAGS[@]} > 0 )); then
  swift test --cache-path "$ROOT_DIR/.build/cache" "${SWIFT_TEST_FLAGS[@]}" "$@"
else
  swift test --cache-path "$ROOT_DIR/.build/cache" "$@"
fi
