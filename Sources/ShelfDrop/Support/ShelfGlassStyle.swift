import SwiftUI

enum ShelfGlassStyle {
    static let cornerRadius: CGFloat = 18
    static let accent = Color(red: 0.24, green: 0.78, blue: 0.48)
}

extension View {
    func shelfGlassPanel(isDropTargeted: Bool) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: ShelfGlassStyle.cornerRadius,
            style: .continuous
        )

        return self
            .glassEffect(.regular, in: shape)
            .overlay {
                shape.strokeBorder(
                    isDropTargeted ? ShelfGlassStyle.accent : Color.white.opacity(0.24),
                    lineWidth: isDropTargeted ? 1.5 : 0.8
                )
            }
            .overlay {
                shape
                    .inset(by: 1.25)
                    .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.5)
            }
    }

    func shelfGlassItem() -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)

        return self
            .glassEffect(.regular.interactive(), in: shape)
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6)
            }
    }

    func shelfGlassControl<S: InsettableShape>(in shape: S) -> some View {
        self
            .glassEffect(.regular.interactive(), in: shape)
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.16), lineWidth: 0.6)
            }
    }
}
