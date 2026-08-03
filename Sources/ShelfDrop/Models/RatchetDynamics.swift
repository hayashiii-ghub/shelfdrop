struct RatchetMotion: Equatable, Sendable {
    let delta: Double
    let accumulatedRotation: Double
    let detentCrossings: Int
    let velocity: Double
}

enum RatchetDynamics {
    static func seconds(in duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    static func advance(
        from previousAngle: Double,
        to currentAngle: Double,
        accumulatedRotation: Double,
        elapsed: Double,
        detentAngle: Double
    ) -> RatchetMotion {
        var delta = currentAngle - previousAngle
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }

        let updatedRotation = accumulatedRotation + delta
        let safeDetentAngle = max(detentAngle, .leastNonzeroMagnitude)
        let previousDetent = Int((accumulatedRotation / safeDetentAngle).rounded(.towardZero))
        let currentDetent = Int((updatedRotation / safeDetentAngle).rounded(.towardZero))
        let safeElapsed = max(elapsed, .leastNonzeroMagnitude)

        return RatchetMotion(
            delta: delta,
            accumulatedRotation: updatedRotation,
            detentCrossings: abs(currentDetent - previousDetent),
            velocity: delta / safeElapsed
        )
    }
}
