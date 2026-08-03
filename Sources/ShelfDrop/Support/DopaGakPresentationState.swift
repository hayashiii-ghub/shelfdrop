import Combine
import Foundation

@MainActor
final class DopaGakPresentationState: ObservableObject {
    @Published var deviceStyle: DeviceStyle {
        didSet {
            defaults.set(deviceStyle.rawValue, forKey: Self.deviceKey)
            onDeviceStyleChange?(deviceStyle)
        }
    }
    @Published var selectedShelfIndex = 0

    let ratchet: RatchetController
    var onDeviceStyleChange: ((DeviceStyle) -> Void)?
    private let defaults: UserDefaults
    private static let deviceKey = "DopaGak.deviceStyle"

    init(defaults: UserDefaults = .standard, feedbackEnabled: Bool = true) {
        ratchet = RatchetController(feedbackEnabled: feedbackEnabled)
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.deviceKey)
        deviceStyle = DeviceStyle(rawValue: saved ?? "") ?? .kurukuru
    }

    func moveShelfSelection(by offset: Int, itemCount: Int) {
        guard itemCount > 0 else {
            selectedShelfIndex = 0
            return
        }
        selectedShelfIndex = (selectedShelfIndex + offset % itemCount + itemCount) % itemCount
    }

    func normalizeShelfSelection(itemCount: Int) {
        guard itemCount > 0 else {
            selectedShelfIndex = 0
            return
        }
        selectedShelfIndex = min(max(0, selectedShelfIndex), itemCount - 1)
    }

    func adjustShelfSelection(removingIndex: Int, itemCountAfterRemoval: Int) {
        if removingIndex < selectedShelfIndex {
            selectedShelfIndex -= 1
        }
        normalizeShelfSelection(itemCount: itemCountAfterRemoval)
    }

    func stopFeedback() {
        ratchet.stop()
    }
}
