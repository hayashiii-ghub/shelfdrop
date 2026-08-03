import Foundation
import Testing
@testable import DopaGak

@MainActor
@Test("Shelf selection wraps without a pseudo-OS destination model")
func shelfSelectionWrapsDirectly() {
    let suiteName = "DopaGakTests.shelfSelectionWrapsDirectly"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let presentation = DopaGakPresentationState(defaults: defaults, feedbackEnabled: false)

    presentation.moveShelfSelection(by: -1, itemCount: 3)
    #expect(presentation.selectedShelfIndex == 2)

    presentation.moveShelfSelection(by: 2, itemCount: 3)
    #expect(presentation.selectedShelfIndex == 1)
}

@MainActor
@Test("Shelf selection is clamped after removal and reset when empty")
func shelfSelectionNormalizesAfterContentChanges() {
    let suiteName = "DopaGakTests.shelfSelectionNormalizesAfterContentChanges"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let presentation = DopaGakPresentationState(defaults: defaults, feedbackEnabled: false)
    presentation.selectedShelfIndex = 4

    presentation.normalizeShelfSelection(itemCount: 2)
    #expect(presentation.selectedShelfIndex == 1)

    presentation.normalizeShelfSelection(itemCount: 0)
    #expect(presentation.selectedShelfIndex == 0)
}

@MainActor
@Test("Removing an earlier row preserves the selected Shelf item")
func shelfSelectionTracksRemovalBeforeSelection() {
    let suiteName = "DopaGakTests.shelfSelectionTracksRemovalBeforeSelection"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let presentation = DopaGakPresentationState(defaults: defaults, feedbackEnabled: false)
    presentation.selectedShelfIndex = 3

    presentation.adjustShelfSelection(removingIndex: 1, itemCountAfterRemoval: 4)
    #expect(presentation.selectedShelfIndex == 2)

    presentation.adjustShelfSelection(removingIndex: 2, itemCountAfterRemoval: 2)
    #expect(presentation.selectedShelfIndex == 1)
}

@MainActor
@Test("Device controls route directly to Shelf actions")
func deviceControlsRouteDirectlyToShelfActions() {
    var events: [String] = []
    let handler = ShelfDeviceCommandHandler(
        move: { events.append("move:\($0)") },
        select: { events.append("select") },
        back: { events.append("back") },
        secondary: { events.append("secondary") },
        addClipboard: { events.append("clipboard") }
    )

    handler.handle(.move(-2))
    handler.handle(.select)
    handler.handle(.secondary)
    handler.handle(.addClipboard)
    handler.handle(.back)

    #expect(events == ["move:-2", "select", "secondary", "clipboard", "back"])
}
