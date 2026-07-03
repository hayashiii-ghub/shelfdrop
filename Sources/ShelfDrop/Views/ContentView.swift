import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    let onCollapseChange: (Bool) -> Void
    let onDismiss: () -> Void
    @State private var isDropTargeted = false
    @State private var isCollapsed = false

    var body: some View {
        VStack(spacing: 0) {
            ShelfHeader(
                count: store.items.count,
                isCollapsed: isCollapsed,
                onToggleCollapsed: toggleCollapsed,
                onDismiss: onDismiss
            )

            if !isCollapsed {
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
        .animation(.easeInOut(duration: 0.16), value: isCollapsed)
        .onDrop(of: ShelfStore.acceptedTypeIdentifiers, isTargeted: $isDropTargeted) { providers in
            guard !isCollapsed else { return false }
            return store.handleDrop(providers: providers)
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

    private func toggleCollapsed() {
        isCollapsed.toggle()
        if isCollapsed {
            isDropTargeted = false
        }
        onCollapseChange(isCollapsed)
    }
}

private struct ShelfHeader: View {
    let count: Int
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
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
                    .frame(width: 108, height: 30)
            }
            .frame(width: 108, height: 30, alignment: .leading)
            .help("Drag to move")

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .frame(width: 20, height: 22)
            .help("Hide Shelf")

            Button(action: onToggleCollapsed) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .frame(width: 20, height: 22)
            .help(isCollapsed ? "Expand Shelf" : "Collapse Shelf")

            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, 12)
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
