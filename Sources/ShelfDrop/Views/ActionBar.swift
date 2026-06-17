import SwiftUI

struct ActionBar: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.exportAllItemsToChosenFolder()
            } label: {
                if store.isExporting {
                    HStack(spacing: 5) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Exporting")
                    }
                } else {
                    Label("Export All...", systemImage: "tray.and.arrow.up")
                }
            }
            .labelStyle(.titleAndIcon)
            .help("Export all items to a folder")

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
