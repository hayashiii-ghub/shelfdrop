import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: validate_app_icon.swift <png>\n", stderr)
    exit(2)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard
    let data = try? Data(contentsOf: url),
    let bitmap = NSBitmapImageRep(data: data),
    bitmap.pixelsWide == 1024,
    bitmap.pixelsHigh == 1024,
    bitmap.hasAlpha
else {
    fputs("App icon master must be 1024x1024 with alpha\n", stderr)
    exit(1)
}

let corners = [
    (0, 0),
    (bitmap.pixelsWide - 1, 0),
    (0, bitmap.pixelsHigh - 1),
    (bitmap.pixelsWide - 1, bitmap.pixelsHigh - 1)
]

for (x, y) in corners {
    guard let color = bitmap.colorAt(x: x, y: y), color.alphaComponent <= 0.01 else {
        fputs("App icon corners must be transparent\n", stderr)
        exit(1)
    }
}

print("Icon master: 1024x1024 RGBA with transparent corners")
