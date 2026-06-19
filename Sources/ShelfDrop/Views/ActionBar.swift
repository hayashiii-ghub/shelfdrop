import SwiftUI

struct ActionBar: View {
    @ObservedObject var store: ShelfStore

    var body: some View {
        HStack(spacing: 8) {
            MultiFileDragSource(
                fileURLs: store.isExporting ? [] : store.items.batchDragFileURLs
            )
            .frame(width: 26, height: 26)
            .shelfGlassControl(in: RoundedRectangle(cornerRadius: 7, style: .continuous))

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
            .frame(width: 26, height: 26)
            .shelfGlassControl(in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .help("Copy All to Folder")

            Button {
                store.moveItemsToChosenFolder()
            } label: {
                Label("Move All to Folder", systemImage: "folder.badge.plus")
            }
            .frame(width: 26, height: 26)
            .shelfGlassControl(in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .help("Move All to Folder")

            Button {
                store.createZipArchive()
            } label: {
                Label("Create ZIP", systemImage: "doc.zipper")
            }
            .frame(width: 26, height: 26)
            .shelfGlassControl(in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .help("Create ZIP Archive")

            Spacer()

            Button(role: .destructive) {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .frame(width: 26, height: 26)
            .shelfGlassControl(in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .help("Clear Shelf")
        }
        .font(.system(size: 14, weight: .medium))
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .disabled(store.items.isEmpty || store.isExporting)
    }
}
