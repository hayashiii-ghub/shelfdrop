import AppKit
import Foundation

enum FileActionMode {
    case copy
    case move
}

struct FileActionService {
    func chooseDestinationFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        return panel.runModal() == .OK ? panel.url : nil
    }

    func chooseZipDestination() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "ShelfDrop-\(Date().compactTimestamp()).zip"
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    func inboxDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseURL.appendingPathComponent("ShelfDrop/Inbox", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func export(items: [ShelfItem], to destination: URL, mode: FileActionMode) throws {
        for item in items {
            try export(item: item, to: destination, mode: mode)
        }
    }

    func createZip(from items: [ShelfItem], destination: URL) throws {
        let stagingRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShelfDrop-\(UUID().uuidString)", isDirectory: true)
        let stagingItems = stagingRoot.appendingPathComponent("ShelfDrop Items", isDirectory: true)
        try FileManager.default.createDirectory(at: stagingItems, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: stagingRoot)
        }

        try export(items: items, to: stagingItems, mode: .copy)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = [
            "-c",
            "-k",
            "--sequesterRsrc",
            "--keepParent",
            stagingItems.path,
            destination.path
        ]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private func export(item: ShelfItem, to destination: URL, mode: FileActionMode) throws {
        switch item.kind {
        case .file, .folder, .image:
            guard let source = item.url else { return }
            let target = destination.availableChildURL(named: item.preferredFileName(fallback: source.lastPathComponent))
            switch mode {
            case .copy:
                try FileManager.default.copyItem(at: source, to: target)
            case .move:
                if item.kind == .image {
                    try FileManager.default.copyItem(at: source, to: target)
                } else {
                    try FileManager.default.moveItem(at: source, to: target)
                }
            }
        case .link:
            let name = item.title.sanitizedFileName(defaultName: "Link") + ".url.txt"
            let target = destination.availableChildURL(named: name)
            try (item.url?.absoluteString ?? item.text ?? "").write(to: target, atomically: true, encoding: .utf8)
        case .text:
            let name = item.title.sanitizedFileName(defaultName: "Text") + ".txt"
            let target = destination.availableChildURL(named: name)
            try (item.text ?? "").write(to: target, atomically: true, encoding: .utf8)
        }
    }
}
