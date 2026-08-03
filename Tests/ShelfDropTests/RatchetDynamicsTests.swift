import Testing
@testable import DopaGak

@Test("wheel wraparound keeps the short arc and counts detents")
func wheelWraparoundKeepsShortArc() {
    let motion = RatchetDynamics.advance(
        from: 350,
        to: 10,
        accumulatedRotation: 0,
        elapsed: 0.1,
        detentAngle: 10
    )

    #expect(motion.delta == 20)
    #expect(motion.accumulatedRotation == 20)
    #expect(motion.detentCrossings == 2)
    #expect(motion.velocity == 200)
}

@MainActor
@Test("wheel controller forwards every signed detent crossing")
func wheelControllerForwardsEveryDetentCrossing() {
    let controller = RatchetController(feedbackEnabled: false)
    var receivedCrossings = 0
    controller.onDetent = { receivedCrossings = $0 }

    controller.beginDrag(at: 350)
    controller.drag(to: 10)
    controller.stop()

    #expect(receivedCrossings == 2)
}

@MainActor
@Test("wheel detents and physical buttons use haptic-only feedback routes")
func wheelAndButtonsRouteHapticFeedback() {
    let feedback = SensoryFeedbackSpy()
    let controller = RatchetController(feedback: feedback)

    controller.nudge(direction: 1)
    controller.buttonPress()
    controller.beginDrag(at: 0)
    controller.endDrag()
    controller.stop()

    #expect(feedback.detentCount == 1)
    #expect(feedback.buttonCount == 1)
    #expect(feedback.endGestureCount == 1)
    #expect(feedback.stopCount == 1)
}

@MainActor
private final class SensoryFeedbackSpy: SensoryFeedbackPerforming {
    private(set) var detentCount = 0
    private(set) var buttonCount = 0
    private(set) var endGestureCount = 0
    private(set) var stopCount = 0

    func playDetent() { detentCount += 1 }
    func playButtonPress() { buttonCount += 1 }
    func endGesture() { endGestureCount += 1 }
    func stop() { stopCount += 1 }
}
