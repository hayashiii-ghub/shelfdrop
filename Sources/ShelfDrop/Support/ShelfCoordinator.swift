import AppKit

@MainActor
protocol ShelfWindowPresenting: AnyObject {
    var store: ShelfStore { get }
    var isShelfVisible: Bool { get }
    var shelfFrame: NSRect? { get }

    func showShelf(avoiding occupiedFrames: [NSRect])
    func hideShelf()
}

@MainActor
final class ShelfCoordinator {
    typealias ShelfFactory = @MainActor () -> any ShelfWindowPresenting

    private let makeShelf: ShelfFactory
    private var shelves: [any ShelfWindowPresenting] = []

    init(makeShelf: @escaping ShelfFactory = {
        ShelfWindowController(store: ShelfStore())
    }) {
        self.makeShelf = makeShelf
    }

    var activeStore: ShelfStore? {
        shelves.last(where: \.isShelfVisible)?.store ?? shelves.last?.store
    }

    func discardStaleManagedFiles() {
        shelfForNewInput().store.discardStaleManagedFiles()
    }

    func openShelfForDrag() {
        show(shelfForNewInput())
    }

    func addFinderSelection(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let shelf = shelfForNewInput()
        shelf.store.addFileURLs(urls)
        show(shelf)
    }

    func showAllShelves() {
        if shelves.isEmpty {
            show(makeAndStoreShelf())
            return
        }

        for shelf in shelves {
            show(shelf)
        }
    }

    func clearAll() {
        for shelf in shelves {
            shelf.store.clear()
        }
    }

    private func shelfForNewInput() -> any ShelfWindowPresenting {
        if shelves.contains(where: \.isShelfVisible) {
            return makeAndStoreShelf()
        }
        return shelves.last ?? makeAndStoreShelf()
    }

    private func makeAndStoreShelf() -> any ShelfWindowPresenting {
        let shelf = makeShelf()
        shelves.append(shelf)
        return shelf
    }

    private func show(_ shelf: any ShelfWindowPresenting) {
        let shelfID = ObjectIdentifier(shelf)
        let occupiedFrames = shelves.compactMap { candidate -> NSRect? in
            guard ObjectIdentifier(candidate) != shelfID else { return nil }
            return candidate.shelfFrame
        }
        shelf.showShelf(avoiding: occupiedFrames)
    }
}

enum ShelfPlacement {
    private static let gap: CGFloat = 12

    static func origin(
        preferred: NSPoint,
        size: NSSize,
        visibleFrame: NSRect,
        occupiedFrames: [NSRect]
    ) -> NSPoint {
        let preferred = clamped(preferred, size: size, to: visibleFrame)
        guard overlaps(preferred, size: size, occupiedFrames: occupiedFrames) else {
            return preferred
        }

        for occupied in occupiedFrames.reversed() {
            let candidates = [
                NSPoint(x: occupied.maxX + gap, y: occupied.minY),
                NSPoint(x: occupied.minX - size.width - gap, y: occupied.minY),
                NSPoint(x: occupied.minX, y: occupied.minY - size.height - gap),
                NSPoint(x: occupied.minX, y: occupied.maxY + gap)
            ]

            if let available = candidates.first(where: { candidate in
                fits(candidate, size: size, in: visibleFrame)
                    && !overlaps(candidate, size: size, occupiedFrames: occupiedFrames)
            }) {
                return available
            }
        }

        let cascade = NSPoint(
            x: preferred.x + CGFloat(occupiedFrames.count * 24),
            y: preferred.y - CGFloat(occupiedFrames.count * 24)
        )
        return clamped(cascade, size: size, to: visibleFrame)
    }

    private static func overlaps(
        _ origin: NSPoint,
        size: NSSize,
        occupiedFrames: [NSRect]
    ) -> Bool {
        let frame = NSRect(origin: origin, size: size)
        return occupiedFrames.contains { $0.intersects(frame) }
    }

    private static func fits(_ origin: NSPoint, size: NSSize, in frame: NSRect) -> Bool {
        origin.x >= frame.minX
            && origin.y >= frame.minY
            && origin.x + size.width <= frame.maxX
            && origin.y + size.height <= frame.maxY
    }

    private static func clamped(_ origin: NSPoint, size: NSSize, to frame: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(origin.x, frame.minX), frame.maxX - size.width),
            y: min(max(origin.y, frame.minY), frame.maxY - size.height)
        )
    }
}
