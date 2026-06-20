import AppKit
import SwiftUI

enum ShelfFileDropReader {
    private static let internalDragType = NSPasteboard.PasteboardType(
        ShelfDragPayload.typeIdentifier
    )

    static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        guard pasteboard.availableType(from: [internalDragType]) == nil else {
            return []
        }

        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []

        return objects.compactMap { object in
            guard let url = object as? URL, url.isFileURL else { return nil }
            return url
        }
    }
}

final class ShelfFileDropHostingView: NSHostingView<ContentView> {
    private let onFileURLs: ([URL]) -> Void

    init(rootView: ContentView, onFileURLs: @escaping ([URL]) -> Void) {
        self.onFileURLs = onFileURLs
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropOperation(for: sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropOperation(for: sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = ShelfFileDropReader.fileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        onFileURLs(urls)
        return true
    }

    private func dropOperation(for sender: NSDraggingInfo) -> NSDragOperation {
        ShelfFileDropReader.fileURLs(from: sender.draggingPasteboard).isEmpty ? [] : .copy
    }
}
