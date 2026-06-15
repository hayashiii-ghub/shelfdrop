# ShelfDrop

ShelfDrop is a small macOS shelf app inspired by Dropover. It opens a floating shelf while dragging files so items can be temporarily parked, moved, copied, zipped, or dragged back out.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools
- Swift 5.9 or later

## Build And Run

```sh
./script/build_and_run.sh
```

The script builds the SwiftPM target, stages `dist/ShelfDrop.app`, stops any running ShelfDrop process, and launches the fresh app bundle.

For a compile-only check:

```sh
swift build
```

## Package For Another Mac

```sh
./script/package.sh
```

This creates:

```text
dist/ShelfDrop-macos.zip
```

Send that zip to another Mac, unzip it, and open `ShelfDrop.app`.

With full Xcode installed, the package script builds a universal app for Apple Silicon and Intel Macs. With only Xcode Command Line Tools installed, it falls back to the current Mac architecture.

Because this build is ad hoc signed and not notarized, macOS Gatekeeper may block the first launch. Use Finder's context menu:

1. Control-click `ShelfDrop.app`.
2. Choose `Open`.
3. Choose `Open` again in the warning dialog.

If macOS still says the app is damaged because it came from the internet, remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/ShelfDrop.app
```

Use the actual app path if it is not in `/Applications`.

## GitHub Release Build

Pushing a version tag builds and uploads `ShelfDrop-macos.zip` to GitHub Releases:

```sh
git tag v0.1.0
git push origin v0.1.0
```

## Notes

- The shelf only opens from file drag activity, not ordinary cursor shaking.
- The shelf can be moved by dragging the header area without a preparatory click.
- Generated build output is ignored through `.gitignore`.
