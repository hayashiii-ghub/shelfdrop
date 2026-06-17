import AppKit
import XCTest
@testable import ShelfDrop

@MainActor
final class ShelfStoreDocumentImportTests: XCTestCase {
    func testImportsMarkdownDataAsFile() async throws {
        try await assertDocumentImport(
            typeIdentifier: "net.daringfireball.markdown",
            suggestedName: "notes.md",
            contents: "# Notes",
            expectedExtension: "md"
        )
    }

    func testImportsHTMLDataAsFile() async throws {
        try await assertDocumentImport(
            typeIdentifier: "public.html",
            suggestedName: "page.html",
            contents: "<h1>Page</h1>",
            expectedExtension: "html"
        )
    }

    private func assertDocumentImport(
        typeIdentifier: String,
        suggestedName: String,
        contents: String,
        expectedExtension: String
    ) async throws {
        let store = ShelfStore()
        let provider = NSItemProvider()
        provider.suggestedName = suggestedName
        provider.registerDataRepresentation(
            forTypeIdentifier: typeIdentifier,
            visibility: .all
        ) { completion in
            completion(Data(contents.utf8), nil)
            return nil
        }

        store.importItems(from: [provider])
        let item = try await waitForImportedItem(in: store)

        XCTAssertEqual(item.kind, .file)
        XCTAssertEqual(item.url?.pathExtension, expectedExtension)
        XCTAssertEqual(item.title, suggestedName)

        let url = try XCTUnwrap(item.url)
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), contents)
    }

    private func waitForImportedItem(in store: ShelfStore) async throws -> ShelfItem {
        for _ in 0..<100 {
            if let item = store.items.first {
                return item
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        throw ImportTimeout()
    }
}

private struct ImportTimeout: Error {}
