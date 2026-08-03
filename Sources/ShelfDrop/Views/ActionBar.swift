import SwiftUI

struct ActionBar: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        HStack(spacing: 6) {
            MultiFileDragSource(
                fileURLs: store.isExporting ? [] : store.items.batchDragFileURLs
            )
            .frame(width: 28, height: 28)
            .disabled(store.items.isEmpty || store.isExporting)

            actionButton("clipboard", help: "Add Clipboard Text") {
                store.addClipboardText(NSPasteboard.general.string(forType: .string))
            }
            .disabled(store.isExporting)

            Button {
                store.copyItemsToChosenFolder()
            } label: {
                if store.isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "square.on.square")
                }
            }
            .iconActionButton(help: "Copy All to Folder")
            .disabled(store.items.isEmpty || store.isExporting)

            actionButton("folder.badge.plus", help: "Move All to Folder") {
                store.moveItemsToChosenFolder()
            }
            .disabled(store.items.isEmpty || store.isExporting)

            actionButton("archivebox", help: "Create ZIP Archive") {
                store.createZipArchive()
            }
            .disabled(store.items.isEmpty || store.isExporting)

            Button(role: .destructive) {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .iconActionButton(help: "Clear Shelf")
            .disabled(store.items.isEmpty || store.isExporting)
        }
        .font(.system(size: 13, weight: .regular))
        .symbolRenderingMode(.monochrome)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func actionButton(
        _ systemImage: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .iconActionButton(help: help)
    }
}

private extension View {
    func iconActionButton(help: String) -> some View {
        self
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .help(help)
    }
}
