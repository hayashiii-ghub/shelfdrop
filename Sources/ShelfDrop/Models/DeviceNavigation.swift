import Foundation

enum DeviceStyle: String, CaseIterable, Sendable {
    case kurukuru
    case pochitto
}

enum DeviceCommand: Equatable, Sendable {
    case move(Int)
    case select
    case back
    case secondary
    case addClipboard
}

@MainActor
struct ShelfDeviceCommandHandler {
    let move: (Int) -> Void
    let select: () -> Void
    let back: () -> Void
    let secondary: () -> Void
    let addClipboard: () -> Void

    func handle(_ command: DeviceCommand) {
        switch command {
        case let .move(offset):
            move(offset)
        case .select:
            select()
        case .back:
            back()
        case .secondary:
            secondary()
        case .addClipboard:
            addClipboard()
        }
    }
}
