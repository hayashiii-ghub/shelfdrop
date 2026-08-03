import Testing
@testable import DopaGak

@Suite("Click-wheel scroll cadence")
struct WheelScrollAccumulatorTests {
    @Test("precise trackpad deltas accumulate into a detent without queuing")
    func preciseDeltasAccumulate() {
        var accumulator = WheelScrollAccumulator(preciseThreshold: 8)

        #expect(accumulator.steps(for: 3, isPrecise: true) == 0)
        #expect(accumulator.steps(for: 3, isPrecise: true) == 0)
        #expect(accumulator.steps(for: 3, isPrecise: true) == 1)
        #expect(accumulator.steps(for: 0, isPrecise: true) == 0)
    }

    @Test("direction changes discard opposing residual motion")
    func directionChangeClearsResidual() {
        var accumulator = WheelScrollAccumulator(preciseThreshold: 8)

        #expect(accumulator.steps(for: 6, isPrecise: true) == 0)
        #expect(accumulator.steps(for: -3, isPrecise: true) == 0)
        #expect(accumulator.steps(for: -5, isPrecise: true) == -1)
    }

    @Test("discrete wheels respond immediately and large bursts are bounded")
    func discreteAndBurstInput() {
        var accumulator = WheelScrollAccumulator(preciseThreshold: 8, maximumStepsPerEvent: 3)

        #expect(accumulator.steps(for: 1, isPrecise: false) == 1)
        #expect(accumulator.steps(for: -1, isPrecise: false) == -1)
        #expect(accumulator.steps(for: 80, isPrecise: true) == 3)
        #expect(accumulator.steps(for: 0, isPrecise: true) == 0)
    }

    @Test("extreme finite deltas are clamped before integer conversion")
    func extremeFiniteDeltaIsBounded() {
        var accumulator = WheelScrollAccumulator(preciseThreshold: 8, maximumStepsPerEvent: 3)

        #expect(accumulator.steps(for: .greatestFiniteMagnitude, isPrecise: true) == 3)
        #expect(accumulator.steps(for: -.greatestFiniteMagnitude, isPrecise: true) == -3)
    }

    @Test("ending a gesture clears its subthreshold residual")
    func gestureEndClearsResidual() {
        var accumulator = WheelScrollAccumulator(preciseThreshold: 8)
        #expect(accumulator.steps(for: 7, isPrecise: true) == 0)

        accumulator.reset()

        #expect(accumulator.steps(for: 1, isPrecise: true) == 0)
    }
}
