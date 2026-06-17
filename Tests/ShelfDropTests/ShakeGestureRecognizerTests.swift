import Foundation
import Testing
@testable import ShelfDrop

struct ShakeGestureRecognizerTests {
    @Test func plainMouseMovementDoesNotTrigger() {
        var recognizer = ShakeGestureRecognizer()

        let triggered = shakePositions.enumerated().contains { index, x in
            recognizer.record(
                x: x,
                time: 10 + Double(index) * 0.08,
                isDraggingFile: false
            )
        }

        #expect(!triggered)
    }

    @Test func fileDragShakeTriggers() {
        var recognizer = ShakeGestureRecognizer()

        let triggered = shakePositions.enumerated().contains { index, x in
            recognizer.record(
                x: x,
                time: 10 + Double(index) * 0.08,
                isDraggingFile: true
            )
        }

        #expect(triggered)
    }

    private var shakePositions: [CGFloat] {
        [0, 170, 0, 170, 0, 170, 0]
    }
}
