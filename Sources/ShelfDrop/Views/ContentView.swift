import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    let onDismiss: () -> Void
    @State private var isDropTargeted = false

    var body: some View {
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
            .background(isDropTargeted ? Color.accentColor.opacity(0.12) : Color.clear)

            Divider()

            ActionBar(store: store)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.primary.opacity(0.12),
                    lineWidth: 1
                )
        }
        .onDrop(of: ShelfStore.acceptedTypeIdentifiers, isTargeted: $isDropTargeted) { providers in
            store.handleDrop(providers: providers)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Hide Shelf")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

private struct EmptyShelfView: View {
    var body: some View {
        Text("Drop links, images, or text here.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
