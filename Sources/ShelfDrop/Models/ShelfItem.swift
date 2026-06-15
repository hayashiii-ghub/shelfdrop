import Foundation

enum ShelfItemKind: String, Codable, CaseIterable {
    case file
    case folder
    case link
    case text
    case image

    var systemImage: String {
        switch self {
        case .file:
            "doc"
        case .folder:
            "folder"
        case .link:
            "link"
        case .text:
            "text.alignleft"
        case .image:
            "photo"
        }
    }
}

struct ShelfItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ShelfItemKind
    var title: String
    var detail: String
    var url: URL?
    var text: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: ShelfItemKind,
        title: String,
        detail: String,
        url: URL? = nil,
        text: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.url = url
        self.text = text
        self.createdAt = createdAt
    }
}
