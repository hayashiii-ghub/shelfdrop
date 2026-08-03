import Foundation

struct ShelfInbox {
    private let directoryOverride: URL?
    private let legacyDirectoryOverride: URL?

    init(directoryURL: URL? = nil, legacyDirectoryURL: URL? = nil) {
        directoryOverride = directoryURL
        legacyDirectoryOverride = legacyDirectoryURL
    }

    func directory() throws -> URL {
        let directory: URL
        if let directoryOverride {
            directory = directoryOverride
        } else {
            let baseURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            directory = baseURL.appendingPathComponent("DopaGak/Inbox", isDirectory: true)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func removeManagedItem(at url: URL) {
        guard owns(url) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func copyItem(at sourceURL: URL, named requestedName: String) throws -> URL {
        let destinationURL = try directory().availableChildURL(named: requestedName)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    func removeAllManagedItems() throws {
        let directory = try directory()
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for url in contents {
            try FileManager.default.removeItem(at: url)
        }
    }

    func removeLegacyManagedItems() throws {
        let legacyDirectory: URL
        if let legacyDirectoryOverride {
            legacyDirectory = legacyDirectoryOverride
        } else {
            let baseURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            legacyDirectory = baseURL.appendingPathComponent("ShelfDrop/Inbox", isDirectory: true)
        }
        guard FileManager.default.fileExists(atPath: legacyDirectory.path) else { return }
        try FileManager.default.removeItem(at: legacyDirectory)
    }

    func contentsEqual(_ firstURL: URL, _ secondURL: URL) -> Bool {
        FileManager.default.contentsEqual(
            atPath: firstURL.standardizedFileURL.path,
            andPath: secondURL.standardizedFileURL.path
        )
    }

    private func owns(_ url: URL) -> Bool {
        guard let directory = try? directory() else { return false }
        let directoryPath = directory.standardizedFileURL.path
        let itemPath = url.standardizedFileURL.path
        return itemPath.hasPrefix(directoryPath + "/")
    }
}
