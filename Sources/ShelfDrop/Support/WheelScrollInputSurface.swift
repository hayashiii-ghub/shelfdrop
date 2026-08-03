import AppKit
import SwiftUI

struct WheelScrollAccumulator: Sendable {
    private let preciseThreshold: Double
    private let maximumStepsPerEvent: Int
    private var residual = 0.0

    init(preciseThreshold: Double = 8, maximumStepsPerEvent: Int = 3) {
        self.preciseThreshold = max(preciseThreshold, .leastNonzeroMagnitude)
        self.maximumStepsPerEvent = max(1, maximumStepsPerEvent)
    }

    mutating func steps(for delta: Double, isPrecise: Bool) -> Int {
        guard delta.isFinite, delta != 0 else { return 0 }

        if residual != 0, residual.sign != delta.sign {
            residual = 0
        }

        let threshold = isPrecise ? preciseThreshold : 1
        let accumulated = residual + delta
        let normalized = accumulated / threshold
        let bounded = min(
            max(normalized, -Double(maximumStepsPerEvent)),
            Double(maximumStepsPerEvent)
        )
        let rawSteps = Int(bounded)
        guard rawSteps != 0 else {
            residual = accumulated
            return 0
        }

        residual = accumulated.truncatingRemainder(dividingBy: threshold)
        return min(max(rawSteps, -maximumStepsPerEvent), maximumStepsPerEvent)
    }

    mutating func reset() {
        residual = 0
    }
}

struct WheelScrollInputSurface: NSViewRepresentable {
    let onSteps: (Int) -> Void

    func makeNSView(context: Context) -> ScrollMonitorView {
        let view = ScrollMonitorView()
        view.onSteps = onSteps
        return view
    }

    func updateNSView(_ view: ScrollMonitorView, context: Context) {
        view.onSteps = onSteps
    }

    static func dismantleNSView(_ view: ScrollMonitorView, coordinator: ()) {
        view.stopMonitoring()
    }

    final class ScrollMonitorView: NSView {
        var onSteps: ((Int) -> Void)?
        private var accumulator = WheelScrollAccumulator()
        private var eventMonitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window == nil ? stopMonitoring() : startMonitoring()
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }

        func stopMonitoring() {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
            }
        }

        private func startMonitoring() {
            guard eventMonitor == nil else { return }
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        private func handle(_ event: NSEvent) {
            guard let window, event.window === window, !isHidden, alphaValue > 0 else { return }
            if !event.momentumPhase.isEmpty {
                if event.momentumPhase.contains(.ended) || event.momentumPhase.contains(.cancelled) {
                    accumulator.reset()
                }
                return
            }
            if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
                accumulator.reset()
                return
            }
            let location = convert(event.locationInWindow, from: nil)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2
            guard hypot(location.x - center.x, location.y - center.y) <= radius else { return }

            let delta = abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX)
                ? event.scrollingDeltaY
                : event.scrollingDeltaX
            let steps = accumulator.steps(for: delta, isPrecise: event.hasPreciseScrollingDeltas)
            if steps != 0 {
                onSteps?(steps)
            }
        }

        deinit {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
            }
        }
    }
}
