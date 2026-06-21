import SwiftUI

struct ShelfItemRow: View {
    let item: ShelfItem
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onCopy: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.kind.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 6)

            Button(action: onOpen) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help("Open")

            Button {
                if item.secondaryAction == .copy {
                    onCopy()
                } else {
                    onReveal()
                }
            } label: {
                Image(systemName: item.secondaryAction.systemImage)
            }
            .buttonStyle(.borderless)
            .help(item.secondaryAction.help)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .contextMenu {
            Button("Open", action: onOpen)
            Button("Copy", action: onCopy)
            if item.secondaryAction == .reveal {
                Button("Reveal", action: onReveal)
            }
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
    }

    private var iconColor: Color {
        switch item.kind {
        case .file:
            .blue
        case .folder:
            .orange
        case .link:
            .purple
        case .text:
            .green
        case .image:
            .pink
        }
    }
}
