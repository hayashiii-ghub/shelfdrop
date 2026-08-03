import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("usage: compose_design_qa.swift <reference> <implementation> <output>\n", stderr)
    exit(2)
}

func aspectFit(_ size: NSSize, in bounds: NSRect) -> NSRect {
    let scale = min(bounds.width / size.width, bounds.height / size.height)
    let fitted = NSSize(width: size.width * scale, height: size.height * scale)
    return NSRect(
        x: bounds.midX - fitted.width / 2,
        y: bounds.midY - fitted.height / 2,
        width: fitted.width,
        height: fitted.height
    )
}

let referenceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let implementationURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard let reference = NSImage(contentsOf: referenceURL),
      let implementation = NSImage(contentsOf: implementationURL) else {
    fputs("Could not read QA image inputs\n", stderr)
    exit(1)
}

let canvasSize = NSSize(width: 1600, height: 1000)
let image = NSImage(size: canvasSize)
let leftPanel = NSRect(x: 60, y: 70, width: 710, height: 830)
let rightPanel = NSRect(x: 830, y: 70, width: 710, height: 830)

image.lockFocus()
NSColor(calibratedWhite: 0.055, alpha: 1).setFill()
NSRect(origin: .zero, size: canvasSize).fill()

for panel in [leftPanel, rightPanel] {
    let path = NSBezierPath(roundedRect: panel, xRadius: 24, yRadius: 24)
    NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
    path.fill()
    NSColor(calibratedWhite: 0.24, alpha: 1).setStroke()
    path.lineWidth = 1
    path.stroke()
}

let labelAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.82)
]
NSAttributedString(string: "REFERENCE", attributes: labelAttributes)
    .draw(at: NSPoint(x: leftPanel.minX + 24, y: leftPanel.maxY + 22))
NSAttributedString(string: "IMPLEMENTATION", attributes: labelAttributes)
    .draw(at: NSPoint(x: rightPanel.minX + 24, y: rightPanel.maxY + 22))

let leftBounds = leftPanel.insetBy(dx: 30, dy: 30)
let rightBounds = rightPanel.insetBy(dx: 30, dy: 30)
reference.draw(in: aspectFit(reference.size, in: leftBounds))
implementation.draw(in: aspectFit(implementation.size, in: rightBounds))
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode QA contact sheet\n", stderr)
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
