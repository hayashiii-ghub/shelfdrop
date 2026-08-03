import SwiftUI

struct PochittoDeviceView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var presentation: DopaGakPresentationState
    let onCommand: (DeviceCommand) -> Void
    var enablesWindowDrag = true
    var enablesBatchDrag = true
    private let metrics = DeviceStyle.pochitto.metrics

    var body: some View {
        ZStack(alignment: .top) {
            skeletonShell

            // Empty hardware areas move the panel; the live screen and controls stay above this layer.
            DeviceWindowDragSurface(enablesWindowDrag: enablesWindowDrag)
                .frame(width: metrics.windowDragLayerSize.width, height: metrics.windowDragLayerSize.height)

            VStack(spacing: 0) {
                PolishedScreenBezel(
                    cornerRadius: 9,
                    horizontalPadding: metrics.screenBezelPadding.width,
                    verticalPadding: metrics.screenBezelPadding.height
                ) {
                    DeviceDisplayView(
                        store: store,
                        presentation: presentation,
                        monochrome: true,
                        menuPaneWidth: metrics.shelfMenuPaneWidth,
                        enablesBatchDrag: enablesBatchDrag
                    )
                    .frame(width: metrics.screenSize.width, height: metrics.screenSize.height)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Spacer()
                    Text("4-LEVEL LCD")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                }
                .foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.13).opacity(0.72))
                .shadow(color: .white.opacity(0.30), radius: 0.3, y: 0.5)
                .padding(.horizontal, 18)
                .frame(height: 20)

                PochittoControlDeck(controller: presentation.ratchet, onCommand: onCommand)
                    .frame(height: 173)
            }
            .padding(.top, metrics.topContentInset)
        }
        .frame(width: metrics.deviceSize.width, height: metrics.deviceSize.height)
    }

    private var skeletonShell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Color(red: 0.10, green: 0.07, blue: 0.13).opacity(0.94))

            PochittoInteriorPlate()
                .opacity(0.92)
                .padding(7)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.86, green: 0.72, blue: 0.91).opacity(0.42), location: 0),
                            .init(color: Color(red: 0.55, green: 0.38, blue: 0.64).opacity(0.28), location: 0.36),
                            .init(color: Color(red: 0.31, green: 0.22, blue: 0.38).opacity(0.34), location: 0.72),
                            .init(color: Color(red: 0.68, green: 0.51, blue: 0.75).opacity(0.30), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AcrylicHighlight(cornerRadius: 19)

            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.68), Color(red: 0.55, green: 0.38, blue: 0.65).opacity(0.48), .black.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )

            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.8)
                .padding(5)

            screws
        }
        .shadow(color: .black.opacity(0.26), radius: 8, y: 5)
    }

    private var screws: some View {
        GeometryReader { proxy in
            Group {
                DeviceScrew(tint: Color(red: 0.55, green: 0.48, blue: 0.60))
                    .position(x: 11, y: 11)
                DeviceScrew(tint: Color(red: 0.55, green: 0.48, blue: 0.60))
                    .position(x: 11, y: proxy.size.height - 11)
                DeviceScrew(tint: Color(red: 0.55, green: 0.48, blue: 0.60))
                    .position(x: proxy.size.width - 11, y: proxy.size.height - 11)
            }
        }
    }
}

private struct PochittoControlDeck: View {
    @ObservedObject var controller: RatchetController
    let onCommand: (DeviceCommand) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                DPadView(controller: controller, onCommand: onCommand)
                    .position(x: 56, y: 49)

                ABButtonCluster(controller: controller, onCommand: onCommand)
                    .position(x: proxy.size.width - 58, y: 49)

                HStack(spacing: 8) {
                    PochittoCapsuleButton(title: "SELECT") { perform(.addClipboard) }
                    PochittoCapsuleButton(title: "START") { perform(.secondary) }
                }
                .position(x: 90, y: 120)

                SpeakerGrille()
                    .position(x: proxy.size.width - 47, y: 125)

                Circle()
                    .fill(Color(red: 0.83, green: 0.06, blue: 0.20))
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(.white.opacity(0.46), lineWidth: 0.5))
                    .shadow(color: Color.red.opacity(0.42), radius: 2)
                    .position(x: proxy.size.width / 2, y: 91)
            }
        }
    }

    private func perform(_ command: DeviceCommand) {
        controller.buttonPress()
        onCommand(command)
    }
}

private struct PochittoCapsuleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .tracking(0.45)
                .foregroundStyle(.white.opacity(0.76))
                .frame(width: 48, height: 18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.19, green: 0.16, blue: 0.21), Color(red: 0.055, green: 0.045, blue: 0.065)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.65))
                .shadow(color: .black.opacity(0.42), radius: 1.5, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct DPadView: View {
    @ObservedObject var controller: RatchetController
    let onCommand: (DeviceCommand) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(buttonGradient)
                .frame(width: 72, height: 24)
            RoundedRectangle(cornerRadius: 5)
                .fill(buttonGradient)
                .frame(width: 24, height: 72)

            dpadButton("chevron.up", offset: CGSize(width: 0, height: -23)) { controller.nudge(direction: -1) }
            dpadButton("chevron.down", offset: CGSize(width: 0, height: 23)) { controller.nudge(direction: 1) }
            dpadButton("chevron.left", offset: CGSize(width: -23, height: 0)) { perform(.back) }
            dpadButton("chevron.right", offset: CGSize(width: 23, height: 0)) { perform(.select) }

            Circle()
                .fill(RadialGradient(colors: [.black.opacity(0.32), .black.opacity(0.68)], center: .topLeading, startRadius: 0, endRadius: 13))
                .frame(width: 17, height: 17)
                .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 0.8))
        }
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.13), lineWidth: 0.7).frame(width: 72, height: 24)
                RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.13), lineWidth: 0.7).frame(width: 24, height: 72)
            }
        }
        .frame(width: 74, height: 74)
        .shadow(color: .black.opacity(0.44), radius: 3, y: 2)
        .accessibilityLabel("Directional pad")
    }

    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.17, blue: 0.19), Color(red: 0.045, green: 0.042, blue: 0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func dpadButton(_ symbol: String, offset: CGSize, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(.white.opacity(0.26))
                .shadow(color: .black.opacity(0.8), radius: 1, y: 1)
        }
        .buttonStyle(.plain)
        .frame(width: 22, height: 22)
        .offset(offset)
    }

    private func perform(_ command: DeviceCommand) {
        controller.buttonPress()
        onCommand(command)
    }
}

private struct ABButtonCluster: View {
    @ObservedObject var controller: RatchetController
    let onCommand: (DeviceCommand) -> Void

    var body: some View {
        HStack(spacing: 8) {
            roundButton("B") { perform(.back) }.offset(y: 8)
            roundButton("A") { perform(.select) }.offset(y: -7)
        }
        .rotationEffect(.degrees(-10))
    }

    private func roundButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                .frame(width: 38, height: 38)
                .background(
                    RadialGradient(
                        colors: [Color(red: 0.38, green: 0.22, blue: 0.31), Color(red: 0.20, green: 0.08, blue: 0.15), Color(red: 0.09, green: 0.04, blue: 0.07)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 38
                    ),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 0.85).padding(1))
                .overlay(alignment: .topLeading) {
                    Circle().fill(.white.opacity(0.26)).frame(width: 8, height: 3.5).blur(radius: 0.7).offset(x: 8, y: 6)
                }
                .shadow(color: .black.opacity(0.46), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func perform(_ command: DeviceCommand) {
        controller.buttonPress()
        onCommand(command)
    }
}

private struct SpeakerGrille: View {
    var body: some View {
        VStack(spacing: 3.2) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 3.2) {
                    ForEach(0..<5, id: \.self) { column in
                        Circle()
                            .fill(
                                RadialGradient(colors: [.black.opacity(0.88), .black.opacity(0.35)], center: .center, startRadius: 0, endRadius: 3)
                            )
                            .frame(width: 3.8, height: 3.8)
                            .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 0.5))
                            .opacity((row + column).isMultiple(of: 2) ? 1 : 0.72)
                    }
                }
            }
        }
        .frame(width: 43, height: 43)
        .background(.black.opacity(0.13), in: Circle())
        .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 0.6))
        .rotationEffect(.degrees(-16))
    }
}
