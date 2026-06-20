import AppKit
import OSLog
import SwiftUI

private let windowLogger = Logger(
    subsystem: "work.hayashigoto.ShelfDrop",
    category: "Windowing"
)

final class ShelfWindowController: NSObject, NSWindowDelegate {
    // Matches the approved menu bar glyph's measured 742 x 847 bounds.
    private static let approvedIconAspectRatio: CGFloat = 742 / 847
    private static let shelfWidth: CGFloat = 240
    private static let shelfSize = NSSize(
        width: shelfWidth,
        height: shelfWidth / approvedIconAspectRatio
    )
    private static let shelfOpacity: CGFloat = 0.9

    private let store: ShelfStore
    private var panel: NSPanel?
    private var localKeyDownMonitor: Any?

    init(store: ShelfStore) {
        self.store = store
    }

    func showShelf() {
        let panel = shelfPanel()

        if !panel.isVisible {
            positionNearPointer(panel)
            startEscapeKeyMonitor()
        }

        panel.orderFrontRegardless()
        windowLogger.info("Shelf shown")
    }

    func hideShelf() {
        panel?.orderOut(nil)
        stopEscapeKeyMonitor()
        windowLogger.info("Shelf hidden")
    }

    private func shelfPanel() -> NSPanel {
        if let panel {
            return panel
        }

        let size = Self.shelfSize
        let panel = ShelfPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.identifier = NSUserInterfaceItemIdentifier("ShelfDropShelfPanel")
        let contentView = ShelfFileDropHostingView(
            rootView: ContentView(
                store: store,
                onDismiss: { [weak self] in
                    self?.hideShelf()
                }
            ),
            onFileURLs: { [weak self] urls in
                self?.store.addFileURLs(urls)
            }
        )
        contentView.frame = NSRect(origin: .zero, size: size)
        contentView.autoresizingMask = [.width, .height]
        panel.contentView = contentView
        panel.backgroundColor = .clear
        panel.alphaValue = Self.shelfOpacity
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.delegate = self

        self.panel = panel
        return panel
    }

    private func positionNearPointer(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let size = panel.frame.size
        var origin = NSPoint(
            x: mouseLocation.x - size.width / 2,
            y: mouseLocation.y - size.height - 24
        )

        if origin.y < visibleFrame.minY {
            origin.y = mouseLocation.y + 24
        }

        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - size.width - 8)
        origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - size.height - 8)

        panel.setFrameOrigin(origin)
    }

    private func startEscapeKeyMonitor() {
        stopEscapeKeyMonitor()
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hideShelf()
                return nil
            }
            return event
        }
    }

    private func stopEscapeKeyMonitor() {
        if let localKeyDownMonitor {
            NSEvent.removeMonitor(localKeyDownMonitor)
            self.localKeyDownMonitor = nil
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideShelf()
        return false
    }
}

private final class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}
