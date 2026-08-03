import AppKit
import OSLog
import SwiftUI

private let windowLogger = Logger(
    subsystem: "work.hayashigoto.dopagak",
    category: "Windowing"
)

@MainActor
final class ShelfWindowController: NSObject, NSWindowDelegate {
    private let store: ShelfStore
    let presentation = DopaGakPresentationState()
    private var panel: NSPanel?
    private var localKeyDownMonitor: Any?

    init(store: ShelfStore) {
        self.store = store
        super.init()
        presentation.onDeviceStyleChange = { [weak self] style in
            self?.resizePanel(for: style)
        }
        presentation.ratchet.onDetent = { [weak self] direction in
            self?.handleCommand(.move(direction))
        }
    }

    func showShelf() {
        let panel = shelfPanel()
        if !panel.isVisible {
            positionNearPointer(panel)
            startKeyMonitor()
        }
        panel.orderFrontRegardless()
        panel.makeKey()
        windowLogger.info("DopaGak shown")
    }

    func showShelfContent() {
        presentation.selectedShelfIndex = max(0, store.items.count - 1)
        showShelf()
    }

    func toggleShelf() {
        panel?.isVisible == true ? hideShelf() : showShelf()
    }

    func hideShelf() {
        presentation.stopFeedback()
        panel?.orderOut(nil)
        stopKeyMonitor()
        windowLogger.info("DopaGak hidden")
    }

    func selectDevice(_ style: DeviceStyle) {
        presentation.deviceStyle = style
        showShelf()
    }

    private func shelfPanel() -> NSPanel {
        if let panel { return panel }
        let size = Self.size(for: presentation.deviceStyle)
        let panel = ShelfPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.identifier = NSUserInterfaceItemIdentifier("DopaGakDevicePanel")
        panel.contentViewController = NSHostingController(
            rootView: ContentView(
                store: store,
                presentation: presentation,
                onCommand: { [weak self] command in self?.handleCommand(command) }
            )
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isRestorable = false
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false
        panel.delegate = self
        self.panel = panel
        return panel
    }

    private func resizePanel(for style: DeviceStyle) {
        guard let panel else { return }
        let targetSize = Self.size(for: style)
        var frame = panel.frame
        let topEdge = frame.maxY
        frame.size = targetSize
        frame.origin.y = topEdge - targetSize.height
        if let visibleFrame = panel.screen?.visibleFrame {
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX + 8), visibleFrame.maxX - targetSize.width - 8)
            frame.origin.y = min(max(frame.origin.y, visibleFrame.minY + 8), visibleFrame.maxY - targetSize.height - 8)
        }
        panel.setFrame(frame, display: true, animate: true)
    }

    private static func size(for style: DeviceStyle) -> NSSize {
        style.metrics.panelSize
    }

    private func positionNearPointer(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }
        let size = panel.frame.size
        var origin = NSPoint(x: mouseLocation.x - size.width / 2, y: mouseLocation.y - size.height - 24)
        if origin.y < visibleFrame.minY { origin.y = mouseLocation.y + 24 }
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - size.width - 8)
        origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
    }

    private func startKeyMonitor() {
        stopKeyMonitor()
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard let panel = self.panel, event.window === panel else { return event }
            switch event.keyCode {
            case 53:
                self.presentation.ratchet.buttonPress()
                self.handleCommand(.back)
                return nil
            case 126:
                self.presentation.ratchet.nudge(direction: -1)
                return nil
            case 125:
                self.presentation.ratchet.nudge(direction: 1)
                return nil
            case 123:
                self.presentation.ratchet.buttonPress()
                self.handleCommand(.back)
                return nil
            case 124, 36:
                self.presentation.ratchet.buttonPress()
                self.handleCommand(.select)
                return nil
            case 49:
                self.presentation.ratchet.buttonPress()
                self.handleCommand(.secondary)
                return nil
            default:
                return event
            }
        }
    }

    private func handleCommand(_ command: DeviceCommand) {
        commandHandler.handle(command)
    }

    private var commandHandler: ShelfDeviceCommandHandler {
        ShelfDeviceCommandHandler(
            move: { [weak self] offset in
                guard let self else { return }
                presentation.moveShelfSelection(by: offset, itemCount: store.items.count)
            },
            select: { [weak self] in
                guard let self, let item = selectedItem else { return }
                store.open(item)
            },
            back: { [weak self] in
                self?.hideShelf()
            },
            secondary: { [weak self] in
                guard let self, let item = selectedItem else { return }
                store.reveal(item)
            },
            addClipboard: { [weak self] in
                guard let self,
                      store.addClipboardText(NSPasteboard.general.string(forType: .string)) else { return }
                presentation.selectedShelfIndex = max(0, store.items.count - 1)
            }
        )
    }

    private var selectedItem: ShelfItem? {
        guard store.items.indices.contains(presentation.selectedShelfIndex) else { return nil }
        return store.items[presentation.selectedShelfIndex]
    }

    private func stopKeyMonitor() {
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
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
