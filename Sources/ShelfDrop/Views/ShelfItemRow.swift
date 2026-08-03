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
                .font(.system(size: 15, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .tracking(-0.05)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.detail)
                    .font(.system(size: 11, weight: .regular, design: .default))
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
        .font(.system(size: 12, weight: .regular))
        .symbolRenderingMode(.monochrome)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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

}
