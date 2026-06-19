import AppKit
import Testing
@testable import ShelfDrop

@MainActor
struct ShelfCoordinatorTests {
    @Test func dragShakeCreatesIndependentShelfWhenOneIsVisible() throws {
        let fixture = Fixture()

        fixture.coordinator.openShelfForDrag()
        let firstWindow = try fixture.window(at: 0)
        firstWindow.store.items = [ShelfItem(kind: .text, title: "First", detail: "", text: "First")]
        fixture.coordinator.openShelfForDrag()
        let secondWindow = try fixture.window(at: 1)

        #expect(fixture.windows.count == 2)
        #expect(firstWindow.isShelfVisible)
        #expect(secondWindow.isShelfVisible)
        #expect(firstWindow.store.items.map(\.title) == ["First"])
        #expect(secondWindow.store.items.isEmpty)
    }

    @Test func finderSelectionCreatesIndependentShelfWhenOneIsVisible() throws {
        let fixture = Fixture()
        let firstURL = URL(fileURLWithPath: "/tmp/first.txt")
        let secondURL = URL(fileURLWithPath: "/tmp/second.md")

        fixture.coordinator.addFinderSelection([firstURL])
        fixture.coordinator.addFinderSelection([secondURL])
        let firstWindow = try fixture.window(at: 0)
        let secondWindow = try fixture.window(at: 1)

        #expect(fixture.windows.count == 2)
        #expect(firstWindow.store.items.map(\.title) == ["first.txt"])
        #expect(secondWindow.store.items.map(\.title) == ["second.md"])
    }

    @Test func reusesMostRecentShelfWhenNoShelfIsVisible() throws {
        let fixture = Fixture()

        fixture.coordinator.openShelfForDrag()
        let window = try fixture.window(at: 0)
        window.hideShelf()
        fixture.coordinator.openShelfForDrag()

        #expect(fixture.windows.count == 1)
        #expect(window.showCount == 2)
        #expect(window.isShelfVisible)
    }

    @Test func activeStoreTracksMostRecentVisibleShelf() throws {
        let fixture = Fixture()

        fixture.coordinator.openShelfForDrag()
        let firstStore = fixture.coordinator.activeStore!
        fixture.coordinator.openShelfForDrag()
        let secondStore = fixture.coordinator.activeStore!
        try fixture.window(at: 1).hideShelf()

        #expect(firstStore !== secondStore)
        #expect(fixture.coordinator.activeStore! === firstStore)
    }

    @Test func showAllShelvesRestoresEveryHiddenShelf() throws {
        let fixture = Fixture()

        fixture.coordinator.openShelfForDrag()
        fixture.coordinator.openShelfForDrag()
        fixture.windows.forEach { $0.hideShelf() }
        fixture.coordinator.showAllShelves()
        let firstWindow = try fixture.window(at: 0)
        let secondWindow = try fixture.window(at: 1)

        #expect(fixture.windows.count == 2)
        #expect(firstWindow.isShelfVisible)
        #expect(secondWindow.isShelfVisible)
    }

    @Test func placementMovesNewShelfBesideAnOccupiedShelf() {
        let occupied = NSRect(x: 100, y: 100, width: 240, height: 274)

        let origin = ShelfPlacement.origin(
            preferred: occupied.origin,
            size: occupied.size,
            visibleFrame: NSRect(x: 0, y: 0, width: 1_000, height: 800),
            occupiedFrames: [occupied]
        )

        #expect(origin == NSPoint(x: 352, y: 100))
    }
}

@MainActor
private final class Fixture {
    var windows: [FakeShelfWindow] = []
    lazy var coordinator = ShelfCoordinator { [unowned self] in
        let window = FakeShelfWindow()
        windows.append(window)
        return window
    }

    func window(at index: Int) throws -> FakeShelfWindow {
        guard windows.indices.contains(index) else {
            throw MissingShelfWindow(index: index)
        }
        return windows[index]
    }
}

private struct MissingShelfWindow: Error {
    let index: Int
}

@MainActor
private final class FakeShelfWindow: ShelfWindowPresenting {
    let store = ShelfStore()
    private(set) var isShelfVisible = false
    private(set) var showCount = 0
    var shelfFrame: NSRect? {
        isShelfVisible ? NSRect(x: 0, y: 0, width: 240, height: 274) : nil
    }

    func showShelf(avoiding occupiedFrames: [NSRect]) {
        showCount += 1
        isShelfVisible = true
    }

    func hideShelf() {
        isShelfVisible = false
    }
}
