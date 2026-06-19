import Testing
@testable import ShelfDrop

struct FormattingTests {
    @Test(arguments: [".", ".."])
    func replacesSpecialDirectorySegmentsWithTheFallbackName(input: String) {
        #expect(input.sanitizedFileName(defaultName: "Item") == "Item")
    }
}
