import AppKit

enum ShelfIcon {
    static func templateImage() -> NSImage {
        loadTemplateImage(withExtension: "png")
    }

    static func vectorTemplateImage() -> NSImage {
        loadTemplateImage(withExtension: "svg")
    }

    private static func loadTemplateImage(withExtension fileExtension: String) -> NSImage {
        guard
            let url = Bundle.main.url(forResource: "MenuBarTemplate", withExtension: fileExtension),
            let image = NSImage(contentsOf: url)
        else {
            if fileExtension != "png" {
                return templateImage()
            }
            return NSImage(systemSymbolName: "tray", accessibilityDescription: "ShelfDrop") ?? NSImage()
        }

        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        image.accessibilityDescription = "ShelfDrop"
        return image
    }
}
