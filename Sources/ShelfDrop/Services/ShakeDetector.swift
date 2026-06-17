import AppKit
import Foundation
import UniformTypeIdentifiers

final class ShakeDetector {
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var recognizer = ShakeGestureRecognizer()
    private let onShake: () -> Void

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
    }

    func start() {
        stop()

        let eventMask: NSEvent.EventTypeMask = [.leftMouseDragged, .leftMouseUp]
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handle(event)
        }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        recognizer.reset()
    }

    func triggerForVerification() {
        DispatchQueue.main.async {
            self.onShake()
        }
    }

    private func handle(_ event: NSEvent) {
        guard event.type == .leftMouseDragged else {
            recognizer.reset()
            return
        }

        let triggered = recognizer.record(
            x: NSEvent.mouseLocation.x,
            time: ProcessInfo.processInfo.systemUptime,
            isDraggingFile: UserDefaults.standard.bool(forKey: "shakeDetectionEnabled")
                && Self.isFileDragPasteboardActive()
        )

        if triggered {
            onShake()
        }
    }

    private static func isFileDragPasteboardActive() -> Bool {
        let pasteboard = NSPasteboard(name: .drag)
        let fileTypes = [
            NSPasteboard.PasteboardType(UTType.fileURL.identifier),
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-content-type")
        ]

        return pasteboard.availableType(from: fileTypes) != nil
    }
}

struct ShakeGestureRecognizer {
    private var samples: [(time: TimeInterval, x: CGFloat)] = []
    private var lastTriggerTime: TimeInterval = 0

    mutating func record(x: CGFloat, time: TimeInterval, isDraggingFile: Bool) -> Bool {
        guard isDraggingFile else {
            reset()
            return false
        }

        samples.append((time: time, x: x))
        samples.removeAll { time - $0.time > 0.65 }

        guard time - lastTriggerTime > 1.5 else { return false }
        guard samples.count >= 7 else { return false }

        let deltas = zip(samples, samples.dropFirst())
            .map { $1.x - $0.x }
            .filter { abs($0) > 9 }

        guard deltas.count >= 5 else { return false }

        var directionChanges = 0
        for index in 1..<deltas.count {
            let previous = deltas[index - 1]
            let current = deltas[index]
            if (previous > 0 && current < 0) || (previous < 0 && current > 0) {
                directionChanges += 1
            }
        }

        let xValues = samples.map { $0.x }
        let span = (xValues.max() ?? 0) - (xValues.min() ?? 0)

        guard directionChanges >= 4 && span > 140 else { return false }

        lastTriggerTime = time
        reset()
        return true
    }

    mutating func reset() {
        samples.removeAll()
    }
}
