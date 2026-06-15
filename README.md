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

## Notes

- The shelf only opens from file drag activity, not ordinary cursor shaking.
- The shelf can be moved by dragging the header area without a preparatory click.
- Generated build output is ignored through `.gitignore`.
