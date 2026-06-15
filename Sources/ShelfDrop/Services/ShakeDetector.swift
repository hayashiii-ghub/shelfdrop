import AppKit
import Foundation
import UniformTypeIdentifiers

final class ShakeDetector {
    private var timer: Timer?
    private var samples: [(time: TimeInterval, x: CGFloat)] = []
    private var lastTriggerTime: TimeInterval = 0
    private let onShake: () -> Void

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
    }

    func start() {
        stop()

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.record(
                x: NSEvent.mouseLocation.x,
                isDraggingFile: Self.isFileDragPasteboardActive()
            )
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        samples.removeAll()
    }

    func triggerForVerification() {
        DispatchQueue.main.async {
            self.onShake()
        }
    }

    private func record(x: CGFloat, isDraggingFile: Bool) {
        guard UserDefaults.standard.bool(forKey: "shakeDetectionEnabled"), isDraggingFile else {
            samples.removeAll()
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        samples.append((time: now, x: x))
        samples.removeAll { now - $0.time > 0.65 }

        guard now - lastTriggerTime > 1.5 else { return }
        guard samples.count >= 7 else { return }

        let deltas = zip(samples, samples.dropFirst())
            .map { $1.x - $0.x }
            .filter { abs($0) > 9 }

        guard deltas.count >= 5 else { return }

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

        guard directionChanges >= 4 && span > 140 else { return }

        lastTriggerTime = now
        samples.removeAll()

        DispatchQueue.main.async {
            self.onShake()
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
