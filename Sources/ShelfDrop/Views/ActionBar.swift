import SwiftUI

struct ActionBar: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        HStack(spacing: 8) {
            MultiFileDragSource(
                fileURLs: store.isExporting ? [] : store.items.batchDragFileURLs
            )
            .frame(width: 24, height: 24)
            .disabled(store.items.isEmpty || store.isExporting)

            Button {
                store.addClipboardText(NSPasteboard.general.string(forType: .string))
            } label: {
                Label("Add Clipboard Text", systemImage: "doc.on.clipboard")
            }
            .frame(width: 24, height: 24)
            .help("Add Clipboard Text")
            .disabled(store.isExporting)

            Button {
                store.copyItemsToChosenFolder()
            } label: {
                if store.isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Copy All", systemImage: "doc.on.doc")
                }
            }
            .frame(width: 24, height: 24)
            .help("Copy All to Folder")
            .disabled(store.items.isEmpty || store.isExporting)

            Button {
                store.moveItemsToChosenFolder()
            } label: {
                Label("Move All to Folder", systemImage: "folder.badge.plus")
            }
            .frame(width: 24, height: 24)
            .help("Move All to Folder")
            .disabled(store.items.isEmpty || store.isExporting)

            Button {
                store.createZipArchive()
            } label: {
                Label("Create ZIP", systemImage: "doc.zipper")
            }
            .frame(width: 24, height: 24)
            .help("Create ZIP Archive")
            .disabled(store.items.isEmpty || store.isExporting)

            Spacer()

            Button(role: .destructive) {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .frame(width: 24, height: 24)
            .help("Clear Shelf")
            .disabled(store.items.isEmpty || store.isExporting)
        }
        .font(.system(size: 14, weight: .medium))
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
