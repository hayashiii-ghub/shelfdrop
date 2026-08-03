import AppKit
import SwiftUI

struct DeviceDisplayView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var presentation: DopaGakPresentationState
    let monochrome: Bool
    let menuPaneWidth: CGFloat
    var enablesBatchDrag = true
    @State private var isDropTargeted = false

    private var accent: Color {
        monochrome
            ? Color(red: 0.18, green: 0.24, blue: 0.11)
            : Color(red: 0.02, green: 0.49, blue: 0.83)
    }

    private var background: Color {
        monochrome
            ? Color(red: 0.61, green: 0.66, blue: 0.44)
            : Color(white: 0.96)
    }

    private var ink: Color {
        monochrome
            ? Color(red: 0.08, green: 0.12, blue: 0.05)
            : .black
    }

    private var detailInk: Color {
        monochrome
            ? Color(red: 0.72, green: 0.77, blue: 0.51)
            : .white.opacity(0.94)
    }

    private var selectionFill: LinearGradient {
        monochrome
            ? LinearGradient(
                colors: [Color(red: 0.24, green: 0.32, blue: 0.13), Color(red: 0.12, green: 0.20, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [Color(red: 0.16, green: 0.72, blue: 1), Color(red: 0.005, green: 0.43, blue: 0.83)],
                startPoint: .top,
                endPoint: .bottom
            )
    }

    private var detailBackground: LinearGradient {
        monochrome
            ? LinearGradient(
                colors: [Color(red: 0.20, green: 0.27, blue: 0.12), Color(red: 0.10, green: 0.15, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color(red: 0.28, green: 0.39, blue: 0.55), Color(red: 0.055, green: 0.075, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    var body: some View {
        GeometryReader { proxy in
            let leftWidth = min(menuPaneWidth, proxy.size.width)

            HStack(spacing: 0) {
                menuPane
                    .frame(width: leftWidth, height: proxy.size.height)

                detailPane
                    .frame(width: max(0, proxy.size.width - leftWidth), height: proxy.size.height)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(ink.opacity(0.28))
                    .frame(width: 0.7, height: proxy.size.height)
                    .offset(x: leftWidth - 0.35)
                    .allowsHitTesting(false)
            }
        }
        .background(background)
        .overlay { ScreenTexture(monochrome: monochrome) }
        .overlay {
            Rectangle()
                .stroke(isDropTargeted ? accent : ink.opacity(0.22), lineWidth: isDropTargeted ? 3 : 1)
        }
        .onDrop(of: ShelfStore.acceptedTypeIdentifiers, isTargeted: $isDropTargeted) { providers in
            let accepted = store.handleDrop(providers: providers)
            if accepted {
                presentation.ratchet.buttonPress()
            }
            return accepted
        }
        .onAppear {
            presentation.normalizeShelfSelection(itemCount: store.items.count)
        }
        .onChange(of: store.items.count) { _, itemCount in
            presentation.normalizeShelfSelection(itemCount: itemCount)
        }
    }

    private var menuPane: some View {
        VStack(spacing: 0) {
            shelfStatusBar
            Divider().overlay(ink.opacity(0.5))

            if store.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 21, weight: .light))
                    Text("DROP FILES")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .tracking(0.25)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(ink.opacity(0.72))
            } else {
                itemList
            }
        }
        .foregroundStyle(ink)
        .background(
            LinearGradient(
                colors: monochrome
                    ? [background.opacity(0.96), Color(red: 0.55, green: 0.61, blue: 0.38)]
                    : [.white, Color(white: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var shelfStatusBar: some View {
        let batchURLs = store.items.batchDragFileURLs

        return HStack(spacing: 4) {
            Text("SHELF")
                .font(.system(size: 9.5, weight: .bold, design: monochrome ? .monospaced : .default))
                .tracking(monochrome ? 0.35 : -0.1)
            Spacer(minLength: 2)
            if batchURLs.count > 1 {
                ZStack {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .font(.system(size: 8.5, weight: .semibold))
                        .allowsHitTesting(false)
                    if enablesBatchDrag {
                        MultiFileDragSource(fileURLs: batchURLs)
                            .opacity(0.001)
                    }
                }
                .frame(width: 14, height: 14)
                .help("Drag All Files")
            }
            Image(systemName: "battery.75percent")
                .font(.system(size: 9.5, weight: .bold))
        }
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(
            LinearGradient(
                colors: monochrome ? [ink.opacity(0.04), ink.opacity(0.15)] : [.white, Color(white: 0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(monochrome ? 0.08 : 0.78))
                .frame(height: 0.7)
        }
    }

    private var itemList: some View {
        VStack(spacing: 0) {
            ForEach(visibleItemIndices, id: \.self) { index in
                let item = store.items[index]
                Button {
                    presentation.ratchet.buttonPress()
                    presentation.selectedShelfIndex = index
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.kind.systemImage)
                            .frame(width: 12)
                        Text(item.displayTitle)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                        if index == presentation.selectedShelfIndex {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7, weight: .bold))
                        }
                    }
                    .font(.system(size: monochrome ? 9.5 : 10.5, weight: .semibold, design: monochrome ? .monospaced : .default))
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .foregroundStyle(index == presentation.selectedShelfIndex ? Color.white : ink)
                    .background {
                        if index == presentation.selectedShelfIndex {
                            selectionFill
                        }
                    }
                }
                .buttonStyle(.plain)
                .id(item.id)
                .onDrag { item.dragProvider() }
                .contextMenu {
                    Button("Open") { performHaptic { store.open(item) } }
                    Button("Copy") { performHaptic { store.copyToPasteboard(item) } }
                    if item.secondaryAction == .reveal {
                        Button("Reveal") { performHaptic { store.reveal(item) } }
                    }
                    Divider()
                    Button("Remove", role: .destructive) {
                        performHaptic { remove(item, at: index) }
                    }
                }

                Divider().overlay(ink.opacity(0.12))
            }

            Spacer(minLength: 0)
        }
    }

    private var visibleItemIndices: [Int] {
        let visibleCount = min(5, store.items.count)
        guard visibleCount > 0 else { return [] }

        let selectedIndex = min(max(0, presentation.selectedShelfIndex), store.items.count - 1)
        let preferredStart = selectedIndex - visibleCount / 2
        let maximumStart = store.items.count - visibleCount
        let start = min(max(0, preferredStart), maximumStart)
        return Array(start..<(start + visibleCount))
    }

    private var detailPane: some View {
        VStack(spacing: 7) {
            if let item = selectedItem {
                Spacer(minLength: 4)
                Image(systemName: item.kind.systemImage)
                    .font(.system(size: monochrome ? 26 : 32, weight: .light))
                Text(item.displayTitle)
                    .font(.system(size: monochrome ? 9 : 10, weight: .bold, design: monochrome ? .monospaced : .default))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(item.detail)
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .opacity(0.66)
                Spacer(minLength: 2)
                HStack(spacing: 3) {
                    detailButton(systemName: "arrow.up.right.square", help: "Open") {
                        store.open(item)
                    }
                    detailButton(systemName: "doc.on.clipboard", help: "Copy") {
                        store.copyToPasteboard(item)
                    }
                    if item.secondaryAction == .reveal {
                        detailButton(systemName: "magnifyingglass", help: "Reveal") {
                            store.reveal(item)
                        }
                    }
                    detailButton(systemName: "xmark.circle", help: "Remove", destructive: true) {
                        remove(item, at: presentation.selectedShelfIndex)
                    }
                }
                .padding(.bottom, 7)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: monochrome ? 27 : 34, weight: .light))
                Text("DROP FILES")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                Text("READY")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .opacity(0.68)
            }
        }
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(detailInk)
        .background(detailBackground)
    }

    private var selectedItem: ShelfItem? {
        guard store.items.indices.contains(presentation.selectedShelfIndex) else { return nil }
        return store.items[presentation.selectedShelfIndex]
    }

    private func detailButton(
        systemName: String,
        help: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            presentation.ratchet.buttonPress()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(destructive ? Color(red: 1, green: 0.48, blue: 0.48) : detailInk)
                .frame(width: 20, height: 18)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func performHaptic(_ action: () -> Void) {
        presentation.ratchet.buttonPress()
        action()
    }

    private func remove(_ item: ShelfItem, at index: Int) {
        store.remove(item)
        presentation.adjustShelfSelection(
            removingIndex: index,
            itemCountAfterRemoval: store.items.count
        )
    }
}

private struct ScreenTexture: View {
    let monochrome: Bool

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let spacing: CGFloat = monochrome ? 2 : 3
                var y: CGFloat = 0
                while y < size.height {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(
                        line,
                        with: .color(monochrome ? .black.opacity(0.025) : .white.opacity(0.035)),
                        lineWidth: 0.5
                    )
                    y += spacing
                }
            }
            .overlay {
                LinearGradient(
                    colors: [.white.opacity(monochrome ? 0.08 : 0.20), .clear, .black.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .allowsHitTesting(false)
    }
}
