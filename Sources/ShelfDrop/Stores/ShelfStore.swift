import AppKit
import Foundation
import UniformTypeIdentifiers

private struct FileExportSummaryError: LocalizedError {
    let result: FileExportResult
    let totalCount: Int

    var errorDescription: String? {
        "Could Not Export All Items"
    }

    var failureReason: String? {
        let failedItems = result.failures
            .prefix(3)
            .map { "\($0.itemTitle): \($0.message)" }
            .joined(separator: "\n")
        return "Exported \(result.exportedURLs.count) of \(totalCount) items. "
            + "\(result.failures.count) failed.\n\(failedItems)"
    }
}

private struct ArchiveCreationError: LocalizedError {
    let message: String

    var errorDescription: String? {
        "Could Not Create ZIP"
    }

    var failureReason: String? {
        message
    }
}

@MainActor
final class ShelfStore: ObservableObject {
    static let acceptedTypeIdentifiers = ShelfItemImporter.acceptedTypeIdentifiers

    @Published var items: [ShelfItem] = []
    @Published private(set) var isExporting = false

    private let fileActions = FileActionService()
    private let inbox: ShelfInbox
    private let importer: ShelfItemImporter
    private let errorPresenter: @MainActor (Error) -> Void

    init(
        inbox: ShelfInbox = ShelfInbox(),
        errorPresenter: @escaping @MainActor (Error) -> Void = ShelfStore.showAlert
    ) {
        self.inbox = inbox
        importer = ShelfItemImporter(inbox: inbox)
        self.errorPresenter = errorPresenter
    }

    func importItems(from providers: [NSItemProvider]) {
        for provider in providers where
            !provider.hasItemConformingToTypeIdentifier(ShelfDragPayload.typeIdentifier) {
            importer.importItem(from: provider) { [weak self] result in
                Task { @MainActor in
                    self?.addImportedResult(result)
                }
            }
        }
    }

    @discardableResult
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.contains(where: {
            $0.hasItemConformingToTypeIdentifier(ShelfDragPayload.typeIdentifier)
        }) else {
            return false
        }

        importItems(from: providers)
        return true
    }

    func addFileURLs(_ urls: [URL]) {
        for url in urls where url.isFileURL {
            addFileURL(url)
        }
    }

    func remove(_ item: ShelfItem) {
        discardManagedFile(for: item)
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        for item in items {
            discardManagedFile(for: item)
        }
        items.removeAll()
    }

    func discardStaleManagedFiles() {
        do {
            try inbox.removeAllManagedItems()
        } catch {
            present(error)
        }
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
        exportAllItems(to: destination)
    }

    func exportAllItems(to destination: URL) {
        guard !items.isEmpty, !isExporting else { return }

        let itemsToExport = items
        isExporting = true

        Task { @MainActor [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FileActionService().exportAll(items: itemsToExport, to: destination, mode: .copy)
            }.value

            guard let self else { return }
            isExporting = false

            if !result.failures.isEmpty {
                present(FileExportSummaryError(result: result, totalCount: itemsToExport.count))
            }
        }
    }

    func moveItemsToChosenFolder() {
        guard let destination = fileActions.chooseDestinationFolder() else { return }
        moveItems(to: destination)
    }

    func moveItems(to destination: URL) {
        guard !items.isEmpty, !isExporting else { return }

        let itemsToMove = items
        isExporting = true

        Task { @MainActor [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                FileActionService().exportAll(items: itemsToMove, to: destination, mode: .move)
            }.value

            guard let self else { return }
            isExporting = false
            let movedItemIDs = Set(result.exportedItemIDs)
            items.removeAll { movedItemIDs.contains($0.id) }

            if !result.failures.isEmpty {
                present(FileExportSummaryError(result: result, totalCount: itemsToMove.count))
            }
        }
    }

    func createZipArchive() {
        guard let destination = fileActions.chooseZipDestination() else { return }
        createZip(at: destination)
    }

    func createZip(at destination: URL) {
        guard !items.isEmpty, !isExporting else { return }

        let itemsToArchive = items
        isExporting = true

        Task { @MainActor [weak self] in
            let errorMessage = await Task.detached(priority: .userInitiated) { () -> String? in
                do {
                    try FileActionService().createZip(
                        from: itemsToArchive,
                        destination: destination
                    )
                    return nil
                } catch {
                    return error.localizedDescription
                }
            }.value

            guard let self else { return }
            isExporting = false
            if let errorMessage {
                present(ArchiveCreationError(message: errorMessage))
            }
        }
    }

    private func addImportedResult(_ result: ShelfImportResult) {
        switch result {
        case let .file(url, isManaged, detail):
            addFileURL(url, isManagedFile: isManaged, importedDetail: detail)
        case let .link(url):
            addLink(url)
        case let .text(text):
            addText(text)
        }
    }

    private func addFileURL(
        _ url: URL,
        isManagedFile: Bool = false,
        importedDetail: String? = nil
    ) {
        let canonicalURL = url.standardizedFileURL.resolvingSymlinksInPath()
        guard !items.contains(where: { item in
            item.url?.standardizedFileURL.resolvingSymlinksInPath() == canonicalURL
        }) else {
            return
        }

        let kind: ShelfItemKind
        if canonicalURL.isDirectory {
            kind = .folder
        } else if UTType(filenameExtension: canonicalURL.pathExtension)?.conforms(to: .image) == true {
            kind = .image
        } else {
            kind = .file
        }

        if let importedIndex = items.firstIndex(where: { item in
            guard (isManagedFile || item.isManagedFile),
                  let itemURL = item.url else {
                return false
            }
            return inbox.contentsEqual(itemURL, canonicalURL)
        }) {
            if isManagedFile {
                inbox.removeManagedItem(at: canonicalURL)
                return
            }

            let importedURL = items[importedIndex].url
            items[importedIndex] = ShelfItem(
                id: items[importedIndex].id,
                kind: kind,
                title: canonicalURL.lastPathComponent,
                detail: canonicalURL.deletingLastPathComponent().path,
                url: canonicalURL
            )
            importedURL.map(inbox.removeManagedItem)
            return
        }

        items.append(
            ShelfItem(
                kind: kind,
                title: canonicalURL.lastPathComponent,
                detail: importedDetail ?? canonicalURL.deletingLastPathComponent().path,
                url: canonicalURL,
                isManagedFile: isManagedFile
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

    private func discardManagedFile(for item: ShelfItem) {
        guard item.isManagedFile, let url = item.url else { return }
        inbox.removeManagedItem(at: url)
    }

    private func present(_ error: Error) {
        errorPresenter(error)
    }

    private static func showAlert(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

}
