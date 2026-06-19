import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    let onDismiss: () -> Void
    @State private var isDropTargeted = false

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 0) {
                ShelfHeader(count: store.items.count, onDismiss: onDismiss)

                Divider()

                ZStack {
                    if store.items.isEmpty {
                        EmptyShelfView()
                    } else {
                        itemList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isDropTargeted ? ShelfGlassStyle.accent.opacity(0.1) : Color.clear)

                Divider()

                ActionBar(store: store)
            }
            .shelfGlassPanel(isDropTargeted: isDropTargeted)
            .onDrop(of: ShelfStore.acceptedTypeIdentifiers, isTargeted: $isDropTargeted) { providers in
                store.handleDrop(providers: providers)
            }
        }
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(store.items) { item in
                    ShelfItemRow(
                        item: item,
                        onOpen: { store.open(item) },
                        onReveal: { store.reveal(item) },
                        onCopy: { store.copyToPasteboard(item) },
                        onRemove: { store.remove(item) }
                    )
                    .onDrag {
                        return item.dragProvider()
                    }
                }
            }
            .padding(10)
        }
    }
}

private struct ShelfHeader: View {
    let count: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    Image(nsImage: ShelfIcon.templateImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)

                    Text("ShelfDrop")
                        .font(.headline)
                }
                .allowsHitTesting(false)

                WindowDragHandle()
                    .frame(width: 128, height: 30)
            }
            .frame(width: 128, height: 30, alignment: .leading)
            .help("Drag to move")

            Spacer()

            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 24, minHeight: 22)
                .padding(.horizontal, 8)
                .shelfGlassControl(in: Capsule())

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .shelfGlassControl(in: Circle())
            .help("Hide Shelf")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

private struct EmptyShelfView: View {
    var body: some View {
        Text("Drag files, folders, links, or text here.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
