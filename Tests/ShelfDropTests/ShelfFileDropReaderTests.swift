import AppKit
import Testing
@testable import ShelfDrop

struct ShelfFileDropReaderTests {
    @Test func readsFinderFileURLsWithoutFilteringByExtension() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfDropPasteboard-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let urls = ["table.csv", "settings.json", "notes.md", "archive.customext", "Makefile"]
            .map(root.appendingPathComponent)
        for url in urls {
            try Data(url.lastPathComponent.utf8).write(to: url)
        }

        let pasteboard = NSPasteboard(name: .init("ShelfDropTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        #expect(pasteboard.writeObjects(urls.map { $0 as NSURL }))

        #expect(ShelfFileDropReader.fileURLs(from: pasteboard) == urls)
    }

    @Test func rejectsInternalShelfDrags() throws {
        let pasteboard = NSPasteboard(name: .init("ShelfDropTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.declareTypes([
            .fileURL,
            NSPasteboard.PasteboardType(ShelfDragPayload.typeIdentifier)
        ], owner: nil)
        pasteboard.setString(URL(fileURLWithPath: "/tmp/table.csv").absoluteString, forType: .fileURL)
        pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType(ShelfDragPayload.typeIdentifier))

        #expect(ShelfFileDropReader.fileURLs(from: pasteboard).isEmpty)
    }
}
