import AppKit

@MainActor
protocol SensoryFeedbackPerforming: AnyObject {
    func playDetent()
    func playButtonPress()
    func endGesture()
    func stop()
}

@MainActor
final class SensoryFeedbackEngine: SensoryFeedbackPerforming {
    private let enabled: Bool
    private var lastHaptic = ContinuousClock.now - .seconds(1)

    init(enabled: Bool = true) {
        self.enabled = enabled
    }

    func playDetent() {
        let now = ContinuousClock.now
        let interval = RatchetDynamics.seconds(in: lastHaptic.duration(to: now))
        if enabled, interval > 0.04 {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            lastHaptic = now
        }
    }

    func playButtonPress() {
        guard enabled else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        lastHaptic = ContinuousClock.now
    }

    func endGesture() {}

    func stop() {}
}
