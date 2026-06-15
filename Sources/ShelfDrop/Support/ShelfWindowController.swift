import AppKit
import SwiftUI

final class ShelfWindowController: NSObject, NSWindowDelegate {
    private static let shelfSize = NSSize(width: 240, height: 320)
    private static let shelfOpacity: CGFloat = 0.9

    private let store: ShelfStore
    private var panel: NSPanel?
    private var globalMouseDownMonitor: Any?
    private var localKeyDownMonitor: Any?
    private var dismissalTimer: Timer?
    private var shownAt: TimeInterval = 0
    private var outsideSince: TimeInterval?

    init(store: ShelfStore) {
        self.store = store
    }

    func showShelf() {
        let panel = shelfPanel()

        if !panel.isVisible {
            positionNearPointer(panel)
            shownAt = ProcessInfo.processInfo.systemUptime
            outsideSince = nil
            startDismissalBehavior()
        }

        panel.orderFrontRegardless()
    }

    func hideShelf() {
        panel?.orderOut(nil)
        stopDismissalBehavior()
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
        panel.contentViewController = NSHostingController(
            rootView: ContentView(
                store: store,
                onDismiss: { [weak self] in
                    self?.hideShelf()
                }
            )
                .frame(width: size.width, height: size.height)
        )
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

    private func startDismissalBehavior() {
        stopDismissalBehavior()

        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideIfMouseIsOutside()
            }
        }

        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hideShelf()
                return nil
            }
            return event
        }

        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.hideAfterSustainedOutsideHover()
        }
        RunLoop.main.add(timer, forMode: .common)
        dismissalTimer = timer
    }

    private func stopDismissalBehavior() {
        if let globalMouseDownMonitor {
            NSEvent.removeMonitor(globalMouseDownMonitor)
            self.globalMouseDownMonitor = nil
        }

        if let localKeyDownMonitor {
            NSEvent.removeMonitor(localKeyDownMonitor)
            self.localKeyDownMonitor = nil
        }

        dismissalTimer?.invalidate()
        dismissalTimer = nil
        outsideSince = nil
    }

    private func hideIfMouseIsOutside() {
        guard let panel, panel.isVisible else { return }

        if !panel.frame.insetBy(dx: -8, dy: -8).contains(NSEvent.mouseLocation) {
            hideShelf()
        }
    }

    private func hideAfterSustainedOutsideHover() {
        guard let panel, panel.isVisible else {
            stopDismissalBehavior()
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - shownAt > 2.0 else { return }

        if panel.frame.insetBy(dx: -20, dy: -20).contains(NSEvent.mouseLocation) {
            outsideSince = nil
            return
        }

        if outsideSince == nil {
            outsideSince = now
        }

        if let outsideSince, now - outsideSince > 4.0 {
            hideShelf()
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
