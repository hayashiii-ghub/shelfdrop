import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var presentation: ShelfPresentationState
    let expandedHeight: CGFloat
    let collapsedHeight: CGFloat
    let onCollapseChange: (Bool) -> Void
    let onDismiss: () -> Void
    @State private var isDropTargeted = false
    private let panelShape = RoundedRectangle(cornerRadius: 36, style: .continuous)

    var body: some View {
        VStack(spacing: 0) {
            ShelfHeader(
                count: store.items.count,
                isCollapsed: presentation.isCollapsed,
                onToggleCollapsed: toggleCollapsed,
                onDismiss: onDismiss
            )

            if !presentation.isCollapsed {
                ZStack {
                    if store.items.isEmpty {
                        EmptyShelfView()
                    } else {
                        itemList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)

                ActionBar(store: store)
            }
        }
        .glassEffect(.clear, in: panelShape)
        .overlay {
            panelShape
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.clear,
                    lineWidth: 1.5
                )
        }
        .frame(height: presentation.isCollapsed ? collapsedHeight : expandedHeight, alignment: .top)
        .animation(.smooth(duration: 0.24), value: presentation.isCollapsed)
        .onDrop(of: ShelfStore.acceptedTypeIdentifiers, isTargeted: $isDropTargeted) { providers in
            guard !presentation.isCollapsed else { return false }
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
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }

    private func toggleCollapsed() {
        presentation.isCollapsed.toggle()
        if presentation.isCollapsed {
            isDropTargeted = false
        }
        onCollapseChange(presentation.isCollapsed)
    }
}

private struct ShelfHeader: View {
    let count: Int
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    Image(nsImage: ShelfIcon.templateImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.primary)

                    Text("ShelfDrop")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .tracking(-0.2)
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
                    .font(.system(size: 12, weight: .regular))
            }
            .buttonStyle(.borderless)
            .frame(width: 20, height: 22)
            .help("Hide Shelf")

            Button(action: onToggleCollapsed) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .regular))
            }
            .buttonStyle(.borderless)
            .frame(width: 20, height: 22)
            .help(isCollapsed ? "Expand Shelf" : "Collapse Shelf")

            Text("\(count)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(.clear, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.top, isCollapsed ? 10 : 12)
        .padding(.bottom, isCollapsed ? 10 : 8)
    }
}

private struct EmptyShelfView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 22, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.secondary)

            Text("Drop links, images, or text here.")
                .font(.system(size: 12, weight: .regular, design: .default))
                .tracking(0.05)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
