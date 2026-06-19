import Foundation

enum ShelfItemKind: Sendable {
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

struct ShelfItem: Identifiable, Equatable, Sendable {
    var id: UUID
    var kind: ShelfItemKind
    var title: String
    var detail: String
    var url: URL?
    var text: String?
    var isManagedFile: Bool

    init(
        id: UUID = UUID(),
        kind: ShelfItemKind,
        title: String,
        detail: String,
        url: URL? = nil,
        text: String? = nil,
        isManagedFile: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.url = url
        self.text = text
        self.isManagedFile = isManagedFile
    }
}
