import SwiftUI

struct ActionBar: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        HStack(spacing: 8) {
            MultiFileDragSource(
                fileURLs: store.isExporting ? [] : store.items.batchDragFileURLs
            )
            .frame(width: 20, height: 20)

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
            .help("Copy all items to a folder")

            Button {
                store.moveItemsToChosenFolder()
            } label: {
                Label("Move", systemImage: "arrow.forward")
            }

            Button {
                store.createZipArchive()
            } label: {
                Label("ZIP", systemImage: "archivebox")
            }

            Spacer()

            Button(role: .destructive) {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .help("Clear")
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .disabled(store.items.isEmpty || store.isExporting)
    }
}
