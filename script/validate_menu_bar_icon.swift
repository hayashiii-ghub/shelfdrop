import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: validate_menu_bar_icon.swift <png>\n", stderr)
    exit(2)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard
    let data = try? Data(contentsOf: url),
    let bitmap = NSBitmapImageRep(data: data),
    bitmap.pixelsWide == 36,
    bitmap.pixelsHigh == 36,
    bitmap.hasAlpha
else {
    fputs("Menu bar icon must be a 36x36 RGBA PNG\n", stderr)
    exit(1)
}

let pixelCount = bitmap.pixelsWide * bitmap.pixelsHigh
var visiblePixelCount = 0
var transparentPixelCount = 0

for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide {
        guard let color = bitmap.colorAt(x: x, y: y) else { continue }
        if color.alphaComponent >= 0.1 {
            visiblePixelCount += 1
        } else {
            transparentPixelCount += 1
        }
    }
}

let visibleCoverage = Double(visiblePixelCount) / Double(pixelCount)
let transparentCoverage = Double(transparentPixelCount) / Double(pixelCount)

guard transparentCoverage >= 0.4 else {
    fputs("Menu bar icon background must be transparent\n", stderr)
    exit(1)
}

guard visibleCoverage >= 0.05, visibleCoverage <= 0.6 else {
    fputs("Menu bar icon mask must contain a compact visible glyph\n", stderr)
    exit(1)
}

print("Menu bar icon validation passed")
