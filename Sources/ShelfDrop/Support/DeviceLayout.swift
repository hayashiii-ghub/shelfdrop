import CoreGraphics

struct DeviceMetrics: Equatable, Sendable {
    static let windowInset: CGFloat = 12

    let deviceSize: CGSize
    let screenSize: CGSize
    let screenBezelPadding: CGSize
    let primaryControlSize: CGFloat
    let topContentInset: CGFloat

    var screenBezelSize: CGSize {
        CGSize(
            width: screenSize.width + screenBezelPadding.width * 2,
            height: screenSize.height + screenBezelPadding.height * 2
        )
    }

    var windowDragLayerSize: CGSize { deviceSize }

    var panelSize: CGSize {
        CGSize(
            width: deviceSize.width + Self.windowInset * 2,
            height: deviceSize.height + Self.windowInset * 2
        )
    }

    var shelfMenuPaneWidth: CGFloat {
        screenSize.width / 2
    }
}

extension DeviceStyle {
    var userFacingName: String {
        switch self {
        case .kurukuru: "Click Wheel"
        case .pochitto: "D-Pad"
        }
    }

    var compactUserFacingName: String {
        switch self {
        case .kurukuru: "WHEEL"
        case .pochitto: "D-PAD"
        }
    }

    var metrics: DeviceMetrics {
        switch self {
        case .kurukuru:
            DeviceMetrics(
                deviceSize: CGSize(width: 272, height: 362),
                screenSize: CGSize(width: 212, height: 153),
                screenBezelPadding: CGSize(width: 9, height: 7),
                primaryControlSize: 142,
                topContentInset: 21
            )
        case .pochitto:
            DeviceMetrics(
                deviceSize: CGSize(width: 268, height: 386),
                screenSize: CGSize(width: 226, height: 142),
                screenBezelPadding: CGSize(width: 5, height: 5),
                primaryControlSize: 74,
                topContentInset: 29
            )
        }
    }
}
