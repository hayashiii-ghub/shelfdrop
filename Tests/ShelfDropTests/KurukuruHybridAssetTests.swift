import AppKit
import Foundation
import Testing
@testable import DopaGak

@Suite("KURUKURU hybrid assets")
struct KurukuruHybridAssetTests {
    @Test("Rendered hardware layers are high-resolution transparent PNGs")
    func renderedHardwareLayerContract() throws {
        let assets = [
            ("KurukuruChassisFront.png", width: 1_088, height: 1_448),
            ("KurukuruWheelRing.png", width: 568, height: 568),
            ("KurukuruCenterButton.png", width: 280, height: 280)
        ]

        for asset in assets {
            let url = repositoryRoot
                .appendingPathComponent("Assets", isDirectory: true)
                .appendingPathComponent(asset.0)
            let data = try Data(contentsOf: url)
            let bitmap = try #require(NSBitmapImageRep(data: data))

            #expect(bitmap.pixelsWide == asset.width)
            #expect(bitmap.pixelsHigh == asset.height)
            #expect(bitmap.hasAlpha)
            #expect((bitmap.colorAt(x: 0, y: 0)?.alphaComponent ?? 1) < 0.02)
        }
    }

    @Test("Native UI can resolve every hybrid hardware layer")
    func nativeAssetLoaderResolvesHardwareLayers() {
        for name in ["KurukuruChassisFront", "KurukuruWheelRing", "KurukuruCenterButton"] {
            #expect(DeviceAsset.image(named: name, extension: "png") != nil)
        }
    }

    @Test("Static hardware images are reused across view updates")
    func nativeAssetLoaderCachesHardwareLayers() throws {
        let first = try #require(DeviceAsset.image(named: "KurukuruWheelRing", extension: "png"))
        let second = try #require(DeviceAsset.image(named: "KurukuruWheelRing", extension: "png"))

        #expect(first === second)
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
