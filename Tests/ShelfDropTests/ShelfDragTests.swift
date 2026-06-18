import AppKit
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import ShelfDrop

struct ShelfDragTests {
    @Test func movingItemOntoAnotherItemReordersWithoutDuplicating() {
        let first = ShelfItem(kind: .file, title: "first.txt", detail: "")
        let second = ShelfItem(kind: .file, title: "second.txt", detail: "")
        let third = ShelfItem(kind: .file, title: "third.txt", detail: "")
        let store = ShelfStore()
        store.items = [first, second, third]

        store.move(itemID: first.id, onto: third.id)

        #expect(store.items.map(\.id) == [second.id, third.id, first.id])
        #expect(store.items.count == 3)
    }

    @Test func rowDragProviderIdentifiesAnInternalShelfDrag() {
        let fileURL = URL(fileURLWithPath: "/tmp/notes.md")
        let item = ShelfItem(kind: .file, title: "notes.md", detail: "/tmp", url: fileURL)

        let provider = item.dragProvider()

        #expect(provider.hasItemConformingToTypeIdentifier(ShelfDragPayload.typeIdentifier))
        #expect(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
    }

    @MainActor
    @Test func importingAnInternalRowDragDoesNotDuplicateTheShelfItem() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfDropTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = root.appendingPathComponent("notes.md")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("# Notes".utf8).write(to: fileURL)

        let item = ShelfItem(kind: .file, title: "notes.md", detail: root.path, url: fileURL)
        let store = ShelfStore()
        store.items = [item]

        store.importItems(from: [item.dragProvider()])
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(store.items.map(\.id) == [item.id])
    }

    @Test func batchDragUsesOnlyFileBackedItemsInShelfOrder() {
        let fileURL = URL(fileURLWithPath: "/tmp/notes.md")
        let folderURL = URL(fileURLWithPath: "/tmp/Archive", isDirectory: true)
        let imageURL = URL(fileURLWithPath: "/tmp/image.png")
        let items = [
            ShelfItem(kind: .file, title: "notes.md", detail: "", url: fileURL),
            ShelfItem(kind: .link, title: "Example", detail: "", url: URL(string: "https://example.com")),
            ShelfItem(kind: .folder, title: "Archive", detail: "", url: folderURL),
            ShelfItem(kind: .text, title: "Text", detail: "", text: "Text"),
            ShelfItem(kind: .image, title: "image.png", detail: "", url: imageURL)
        ]

        #expect(items.batchDragFileURLs == [fileURL, folderURL, imageURL])
    }

    @Test func batchFileWriterProvidesAFileURLAndInternalShelfMarker() {
        let fileURL = URL(fileURLWithPath: "/tmp/notes.md")
        let pasteboard = NSPasteboard(name: .drag)
        let writer = ShelfFileDragWriter(fileURL: fileURL)

        let types = writer.writableTypes(for: pasteboard)

        #expect(types.contains(.fileURL))
        #expect(types.contains(ShelfDragPayload.pasteboardType))
        #expect(writer.pasteboardPropertyList(forType: .fileURL) as? String == fileURL.absoluteString)
    }
}
