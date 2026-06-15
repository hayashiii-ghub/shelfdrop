import Foundation

extension ShelfItem {
    func dragProvider() -> NSItemProvider {
        if let url {
            let provider = NSItemProvider(object: url as NSURL)
            provider.suggestedName = preferredFileName(fallback: url.lastPathComponent)

            if kind == .link {
                provider.registerObject(url.absoluteString as NSString, visibility: .all)
            }

            return provider
        }

        if let text {
            let provider = NSItemProvider(object: text as NSString)
            provider.suggestedName = title.sanitizedFileName(defaultName: "Text")
            return provider
        }

        return NSItemProvider(object: title as NSString)
    }
}
