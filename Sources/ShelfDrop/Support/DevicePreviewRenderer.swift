import AppKit
import SwiftUI

@MainActor
enum DevicePreviewRenderer {
    static func renderAll(to directoryURL: URL) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        for style in DeviceStyle.allCases {
            try render(
                style: style,
                backdrop: true,
                populated: false,
                to: directoryURL.appendingPathComponent("\(style.rawValue)-preview.png")
            )
            try render(
                style: style,
                backdrop: false,
                populated: false,
                to: directoryURL.appendingPathComponent("\(style.rawValue)-window-alpha.png")
            )
            try render(
                style: style,
                backdrop: true,
                populated: true,
                to: directoryURL.appendingPathComponent("\(style.rawValue)-populated-preview.png")
            )
        }
    }

    private static func render(
        style: DeviceStyle,
        backdrop: Bool,
        populated: Bool,
        to outputURL: URL
    ) throws {
        let suiteName = "work.hayashigoto.dopagak.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let presentation = DopaGakPresentationState(defaults: defaults, feedbackEnabled: false)
        presentation.deviceStyle = style
        let store = ShelfStore()
        if populated {
            store.items = Self.previewItems
        }
        let content = ZStack {
            if backdrop {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.115, blue: 0.13), Color(red: 0.035, green: 0.032, blue: 0.043)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
            }
            device(style: style, store: store, presentation: presentation)
        }
        .frame(width: 500, height: 600)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw PreviewError.renderFailed
        }
        try pngData.write(to: outputURL, options: .atomic)
        presentation.stopFeedback()
    }

    private static var previewItems: [ShelfItem] {
        [
            ShelfItem(
                kind: .file,
                title: "notes.md",
                detail: "Desktop",
                url: URL(fileURLWithPath: "/tmp/notes.md")
            ),
            ShelfItem(
                kind: .image,
                title: "reference.png",
                detail: "Downloads",
                url: URL(fileURLWithPath: "/tmp/reference.png")
            ),
            ShelfItem(
                kind: .text,
                title: "Draft note",
                detail: "24 characters",
                text: "Remember the next step."
            )
        ]
    }

    @ViewBuilder
    private static func device(
        style: DeviceStyle,
        store: ShelfStore,
        presentation: DopaGakPresentationState
    ) -> some View {
        switch style {
        case .kurukuru:
            KurukuruDeviceView(
                store: store,
                presentation: presentation,
                onCommand: { _ in },
                enablesWindowDrag: false,
                enablesScrollInput: false,
                enablesBatchDrag: false
            )
        case .pochitto:
            PochittoDeviceView(
                store: store,
                presentation: presentation,
                onCommand: { _ in },
                enablesWindowDrag: false,
                enablesBatchDrag: false
            )
        }
    }

    private enum PreviewError: Error {
        case renderFailed
    }
}
