import AppKit
import SwiftUI

struct BrushedAluminumShell: View {
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.80), location: 0),
                            .init(color: Color(white: 0.63), location: 0.20),
                            .init(color: Color(white: 0.72), location: 0.49),
                            .init(color: Color(white: 0.57), location: 0.82),
                            .init(color: Color(white: 0.67), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Canvas { context, size in
                for index in 0..<Int(size.height / 2) {
                    let y = CGFloat(index) * 2 + 0.5
                    var line = Path()
                    line.move(to: CGPoint(x: 5, y: y))
                    line.addLine(to: CGPoint(x: size.width - 5, y: y))
                    let shimmer = 0.008 + Double(index % 5) * 0.0015
                    let tone: Color = index.isMultiple(of: 3) ? .white : .black
                    context.stroke(line, with: .color(tone.opacity(shimmer)), lineWidth: 0.35)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.13), .clear, .black.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.softLight)

            RoundedRectangle(cornerRadius: cornerRadius - 0.5, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.70), .white.opacity(0.12), .black.opacity(0.34)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
                .padding(0.75)
        }
        .shadow(color: .black.opacity(0.24), radius: 7, y: 4)
    }
}

struct PolishedScreenBezel<Content: View>: View {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat,
        horizontalPadding: CGFloat = 5,
        verticalPadding: CGFloat = 5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content
    }

    var body: some View {
        content()
            .clipShape(RoundedRectangle(cornerRadius: max(2, cornerRadius - 5), style: .continuous))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        Color(white: 0.025)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
                            .padding(0.8)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 0.8, y: 0.5)
            }
    }
}

struct DeviceScrew: View {
    var tint = Color(white: 0.72)

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.82), tint, .black.opacity(0.56)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
            Capsule().fill(.black.opacity(0.54)).frame(width: 7, height: 1.3).rotationEffect(.degrees(-22))
        }
        .frame(width: 10, height: 10)
        .overlay(Circle().stroke(.white.opacity(0.38), lineWidth: 0.6))
        .shadow(color: .black.opacity(0.32), radius: 1, y: 1)
    }
}

struct AcrylicHighlight: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.38), location: 0),
                        .init(color: .white.opacity(0.08), location: 0.18),
                        .init(color: .clear, location: 0.42),
                        .init(color: .white.opacity(0.10), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.screen)
            .allowsHitTesting(false)
    }
}

struct PochittoInteriorPlate: View {
    var body: some View {
        if let image = DeviceAsset.image(named: "PochittoSkeletonPlate", extension: "png") {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color(red: 0.18, green: 0.22, blue: 0.16)
        }
    }
}

enum DeviceAsset {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(named name: String, extension fileExtension: String) -> NSImage? {
        let key = "\(name).\(fileExtension)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        if let url = Bundle.main.url(forResource: name, withExtension: fileExtension),
           let image = NSImage(contentsOf: url) {
            cache.setObject(image, forKey: key)
            return image
        }

#if DEBUG
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let developmentURL = sourceRoot
            .appendingPathComponent("Assets", isDirectory: true)
            .appendingPathComponent("\(name).\(fileExtension)")
        guard let image = NSImage(contentsOf: developmentURL) else { return nil }
        cache.setObject(image, forKey: key)
        return image
#else
        return nil
#endif
    }
}
