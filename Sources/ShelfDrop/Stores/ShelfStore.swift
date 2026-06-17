import AppKit
import Foundation
import UniformTypeIdentifiers

final class ShelfStore: ObservableObject {
    private static let documentDataTypeIdentifiers = [
        "net.daringfireball.markdown",
        "public.html"
    ]

    private static let imageDataTypeIdentifiers = [
        UTType.png.identifier,
        UTType.tiff.identifier,
        "public.jpeg",
        "com.compuserve.gif",
        "public.heic",
        "public.heif",
        "public.svg-image",
        "com.adobe.svg",
        "org.webmproject.webp"
    ]

    static let acceptedTypeIdentifiers = [
        UTType.fileURL.identifier,
        UTType.url.identifier,
        UTType.plainText.identifier,
        UTType.text.identifier,
        UTType.utf8PlainText.identifier,
        UTType.image.identifier
    ] + documentDataTypeIdentifiers + imageDataTypeIdentifiers

    @Published var items: [ShelfItem] = []

    private let fileActions = FileActionService()

    func importItems(from providers: [NSItemProvider]) {
        for provider in providers {
            importItem(from: provider)
        }
    }

    func addFileURLs(_ urls: [URL]) {
        for url in urls where url.isFileURL {
            addFileURL(url)
        }
    }

    func remove(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items.removeAll()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func open(_ item: ShelfItem) {
        switch item.kind {
        case .file, .folder, .image:
            guard let url = item.url else { return }
            NSWorkspace.shared.open(url)
        case .link:
            guard let url = item.url else { return }
            NSWorkspace.shared.open(url)
        case .text:
            copyToPasteboard(item)
        }
    }

    func reveal(_ item: ShelfItem) {
        guard let url = item.url else {
            copyToPasteboard(item)
            return
        }

        switch item.kind {
        case .file, .folder, .image:
            NSWorkspace.shared.activateFileViewerSelecting([url])
        case .link:
            copyToPasteboard(item)
        case .text:
            copyToPasteboard(item)
        }
    }

    func copyToPasteboard(_ item: ShelfItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let url = item.url {
            pasteboard.writeObjects([url as NSURL])
        } else if let text = item.text {
            pasteboard.setString(text, forType: .string)
        }
    }

    func copyItemsToChosenFolder() {
        guard let destination = fileActions.chooseDestinationFolder() else { return }
        do {
            try fileActions.export(items: items, to: destination, mode: .copy)
        } catch {
            present(error)
        }
    }

    func moveItemsToChosenFolder() {
        guard let destination = fileActions.chooseDestinationFolder() else { return }
        do {
            try fileActions.export(items: items, to: destination, mode: .move)
            clear()
        } catch {
            present(error)
        }
    }

    func createZipArchive() {
        guard let destination = fileActions.chooseZipDestination() else { return }
        do {
            try fileActions.createZip(from: items, destination: destination)
        } catch {
            present(error)
        }
    }

    private func importItem(from provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = Self.url(from: item) else { return }
                Task { @MainActor in
                    self.addFileURL(url)
                }
            }
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                guard let url = Self.url(from: item) else { return }
                Task { @MainActor in
                    self.addLink(url)
                }
            }
            return
        }

        if let typeIdentifier = Self.documentDataTypeIdentifiers.first(where: {
            provider.hasItemConformingToTypeIdentifier($0)
        }) {
            let suggestedName = provider.suggestedName
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                guard let data else { return }
                Task { @MainActor in
                    self.addDocumentData(
                        data,
                        typeIdentifier: typeIdentifier,
                        suggestedName: suggestedName
                    )
                }
            }
            return
        }

        let imageTypes = Self.imageDataTypeIdentifiers + [UTType.image.identifier]
        if let typeIdentifier = imageTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                guard let data else { return }
                Task { @MainActor in
                    self.addImageData(data, typeIdentifier: typeIdentifier)
                }
            }
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ||
            provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) ||
            provider.hasItemConformingToTypeIdentifier(UTType.utf8PlainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                guard let text = Self.text(from: item) else { return }
                Task { @MainActor in
                    self.addText(text)
                }
            }
            return
        }
    }

    private func addFileURL(_ url: URL) {
        let kind: ShelfItemKind = url.isDirectory ? .folder : .file
        items.append(
            ShelfItem(
                kind: kind,
                title: url.lastPathComponent,
                detail: url.deletingLastPathComponent().path,
                url: url
            )
        )
    }

    private func addLink(_ url: URL) {
        items.append(
            ShelfItem(
                kind: .link,
                title: url.host(percentEncoded: false) ?? url.absoluteString,
                detail: url.absoluteString,
                url: url,
                text: url.absoluteString
            )
        )
    }

    private func addText(_ text: String) {
        let title = text.firstMeaningfulLine(limit: 48)
        items.append(
            ShelfItem(
                kind: .text,
                title: title.isEmpty ? "Text Snippet" : title,
                detail: "\(text.count) characters",
                text: text
            )
        )
    }

    private func addDocumentData(_ data: Data, typeIdentifier: String, suggestedName: String?) {
        do {
            let fileExtension = Self.documentFileExtension(for: typeIdentifier)
            let directory = try fileActions.inboxDirectory()
            let fallbackName = "Document-\(Date().compactTimestamp()).\(fileExtension)"
            let requestedName = Self.fileName(
                suggestedName: suggestedName,
                fallbackName: fallbackName,
                fileExtension: fileExtension
            )
            let url = directory.availableChildURL(named: requestedName)
            try data.write(to: url, options: .atomic)
            items.append(
                ShelfItem(
                    kind: .file,
                    title: url.lastPathComponent,
                    detail: "Imported document",
                    url: url
                )
            )
        } catch {
            present(error)
        }
    }

    private func addImageData(_ data: Data, typeIdentifier: String) {
        do {
            let fileExtension = Self.fileExtension(for: typeIdentifier)
            let directory = try fileActions.inboxDirectory()
            let url = directory.appendingPathComponent("Image-\(Date().compactTimestamp()).\(fileExtension)")
            try data.write(to: url, options: .atomic)
            items.append(
                ShelfItem(
                    kind: .image,
                    title: url.lastPathComponent,
                    detail: "Imported image",
                    url: url
                )
            )
        } catch {
            present(error)
        }
    }

    private static func documentFileExtension(for typeIdentifier: String) -> String {
        switch typeIdentifier {
        case "public.html":
            return "html"
        default:
            return "md"
        }
    }

    private static func fileName(
        suggestedName: String?,
        fallbackName: String,
        fileExtension: String
    ) -> String {
        guard let suggestedName, !suggestedName.isEmpty else {
            return fallbackName
        }

        let cleanName = suggestedName.sanitizedFileName(defaultName: fallbackName)
        if cleanName.lowercased().hasSuffix(".\(fileExtension)") {
            return cleanName
        }

        return "\(cleanName).\(fileExtension)"
    }

    private static func fileExtension(for typeIdentifier: String) -> String {
        switch typeIdentifier {
        case UTType.tiff.identifier:
            return "tiff"
        case "public.jpeg":
            return "jpg"
        case "com.compuserve.gif":
            return "gif"
        case "public.heic":
            return "heic"
        case "public.heif":
            return "heif"
        case "public.svg-image", "com.adobe.svg":
            return "svg"
        case "org.webmproject.webp":
            return "webp"
        default:
            return "png"
        }
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    private static func url(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let url = item as? NSURL {
            return url as URL
        }
        if let data = item as? Data,
           let rawValue = String(data: data, encoding: .utf8) {
            return URL(string: rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let rawValue = item as? String {
            return URL(string: rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func text(from item: NSSecureCoding?) -> String? {
        if let text = item as? String {
            return text
        }
        if let text = item as? NSString {
            return text as String
        }
        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
