import AppKit

enum ShelfIcon {
    static func templateImage() -> NSImage {
        guard
            let url = Bundle.main.url(forResource: "MenuBarTemplate", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return NSImage(systemSymbolName: "tray", accessibilityDescription: "ShelfDrop") ?? NSImage()
        }

        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        image.accessibilityDescription = "ShelfDrop"
        return image
    }
}
