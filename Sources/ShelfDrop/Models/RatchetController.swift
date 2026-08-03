import Combine

@MainActor
final class RatchetController: ObservableObject {
    @Published var rotation = 0.0
    @Published var velocity = 0.0
    @Published private(set) var isDragging = false

    var onDetent: ((Int) -> Void)?

    private let feedback: any SensoryFeedbackPerforming
    private var previousAngle = 0.0
    private var previousTime = ContinuousClock.now
    private let detentAngle = 10.0

    init(feedbackEnabled: Bool = true) {
        feedback = SensoryFeedbackEngine(enabled: feedbackEnabled)
    }

    init(feedback: any SensoryFeedbackPerforming) {
        self.feedback = feedback
    }

    func beginDrag(at angle: Double) {
        isDragging = true
        previousAngle = angle
        previousTime = .now
        velocity *= 0.2
    }

    func drag(to angle: Double) {
        guard isDragging else {
            beginDrag(at: angle)
            return
        }
        let now = ContinuousClock.now
        let elapsed = max(0.001, RatchetDynamics.seconds(in: previousTime.duration(to: now)))
        let motion = RatchetDynamics.advance(
            from: previousAngle,
            to: angle,
            accumulatedRotation: rotation,
            elapsed: elapsed,
            detentAngle: detentAngle
        )
        rotation = motion.accumulatedRotation
        velocity = velocity * 0.58 + motion.velocity * 0.42
        previousAngle = angle
        previousTime = now
        if motion.detentCrossings > 0 {
            feedback.playDetent()
            let signedCrossings = motion.delta >= 0 ? motion.detentCrossings : -motion.detentCrossings
            onDetent?(signedCrossings)
        }
    }

    func endDrag() {
        guard isDragging else { return }
        isDragging = false
        velocity = 0
        feedback.endGesture()
    }

    func nudge(direction: Int) {
        guard direction != 0 else { return }
        feedback.playDetent()
        onDetent?(direction)
    }

    func buttonPress() {
        feedback.playButtonPress()
    }

    func stop() {
        velocity = 0
        isDragging = false
        feedback.stop()
    }
}
