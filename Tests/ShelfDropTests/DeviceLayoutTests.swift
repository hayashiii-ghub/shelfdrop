import CoreGraphics
import Testing
@testable import DopaGak

@Suite("Device layout")
struct DeviceLayoutTests {
    @Test("Both devices are one visual size smaller than the previous shells")
    func compactDeviceDimensions() {
        let kurukuru = DeviceStyle.kurukuru.metrics.deviceSize
        let pochitto = DeviceStyle.pochitto.metrics.deviceSize

        #expect(kurukuru.width < 310)
        #expect(kurukuru.height < 413)
        #expect(pochitto.width < 318)
        #expect(pochitto.height < 416)
    }

    @Test("The panel keeps transparent breathing room around the device silhouette")
    func panelInset() {
        for style in DeviceStyle.allCases {
            let metrics = style.metrics
            #expect(metrics.panelSize.width == metrics.deviceSize.width + DeviceMetrics.windowInset * 2)
            #expect(metrics.panelSize.height == metrics.deviceSize.height + DeviceMetrics.windowInset * 2)
        }
    }

    @Test("The window drag layer spans the hardware body behind interactive controls")
    func windowDragLayerCoversDeviceBody() {
        for style in DeviceStyle.allCases {
            let metrics = style.metrics
            #expect(metrics.windowDragLayerSize == metrics.deviceSize)
        }
    }

    @Test("Click-wheel geometry follows the reference device proportions")
    func kurukuruReferenceProportions() {
        let metrics = DeviceStyle.kurukuru.metrics

        #expect(metrics.deviceSize == CGSize(width: 272, height: 362))
        #expect(metrics.screenBezelSize == CGSize(width: 230, height: 167))
        #expect(metrics.primaryControlSize == 142)
        #expect(metrics.topContentInset + metrics.screenBezelSize.height + 12 + metrics.primaryControlSize + 20 == metrics.deviceSize.height)
    }

    @Test("Device choices use functional labels instead of product names")
    func deviceChoiceLabels() {
        #expect(DeviceStyle.kurukuru.userFacingName == "Click Wheel")
        #expect(DeviceStyle.pochitto.userFacingName == "D-Pad")
        #expect(DeviceStyle.kurukuru.compactUserFacingName == "WHEEL")
        #expect(DeviceStyle.pochitto.compactUserFacingName == "D-PAD")
    }

    @Test("The Shelf menu occupies exactly the left half of every display")
    func shelfMenuUsesHalfWidth() {
        for style in DeviceStyle.allCases {
            let metrics = style.metrics
            #expect(metrics.shelfMenuPaneWidth == metrics.screenSize.width / 2)
        }

        #expect(DeviceStyle.kurukuru.metrics.shelfMenuPaneWidth == 106)
    }
}
