import SwiftUI

struct KurukuruDeviceView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var presentation: DopaGakPresentationState
    let onCommand: (DeviceCommand) -> Void
    var enablesWindowDrag = true
    var enablesScrollInput = true
    var enablesBatchDrag = true
    private let metrics = DeviceStyle.kurukuru.metrics

    var body: some View {
        ZStack(alignment: .top) {
            chassis

            // Empty hardware areas move the panel; the live display and wheel stay above this layer.
            DeviceWindowDragSurface(enablesWindowDrag: enablesWindowDrag)
                .frame(width: metrics.windowDragLayerSize.width, height: metrics.windowDragLayerSize.height)

            DeviceDisplayView(
                store: store,
                presentation: presentation,
                monochrome: false,
                menuPaneWidth: metrics.shelfMenuPaneWidth,
                enablesBatchDrag: enablesBatchDrag
            )
            .frame(width: metrics.screenSize.width, height: metrics.screenSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.08), Color(red: 0.72, green: 0.84, blue: 1).opacity(0.025), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
            .position(
                x: metrics.deviceSize.width / 2,
                y: metrics.topContentInset + metrics.screenBezelPadding.height + metrics.screenSize.height / 2
            )

            KurukuruWheelView(
                controller: presentation.ratchet,
                onCommand: onCommand,
                enablesScrollInput: enablesScrollInput
            )
                .frame(width: metrics.primaryControlSize, height: metrics.primaryControlSize)
                .position(
                    x: metrics.deviceSize.width / 2,
                    y: metrics.topContentInset + metrics.screenBezelSize.height + 12 + metrics.primaryControlSize / 2
                )
        }
        .frame(width: metrics.deviceSize.width, height: metrics.deviceSize.height)
    }

    @ViewBuilder
    private var chassis: some View {
        if let image = DeviceAsset.image(named: "KurukuruChassisFront", extension: "png") {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .frame(width: metrics.deviceSize.width, height: metrics.deviceSize.height)
                .shadow(color: .black.opacity(0.24), radius: 7, y: 4)
                .allowsHitTesting(false)
        } else {
            BrushedAluminumShell(cornerRadius: 23)
        }
    }
}

private struct KurukuruWheelView: View {
    @ObservedObject var controller: RatchetController
    let onCommand: (DeviceCommand) -> Void
    let enablesScrollInput: Bool

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let labelOffset = proxy.size.width * 0.39
            ZStack {
                wheelRing

                Color.clear
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                controller.drag(to: angle(for: value.location, center: center))
                            }
                            .onEnded { _ in controller.endDrag() }
                    )

                if enablesScrollInput {
                    WheelScrollInputSurface { steps in
                        controller.nudge(direction: steps)
                    }
                    .clipShape(Circle())
                }

                wheelButton("MENU", action: { perform(.back) })
                    .font(.system(size: 9.5, weight: .medium))
                    .offset(y: -labelOffset)
                wheelButton(systemName: "backward.end.fill", action: { controller.nudge(direction: -1) })
                    .offset(x: -labelOffset)
                wheelButton(systemName: "forward.end.fill", action: { controller.nudge(direction: 1) })
                    .offset(x: labelOffset)
                wheelButton(systemName: "playpause.fill", action: { perform(.secondary) })
                    .offset(y: labelOffset)

                Button { perform(.select) } label: {
                    centerButton
                }
                .buttonStyle(.plain)
                .frame(width: proxy.size.width * 0.49, height: proxy.size.width * 0.49)
                .scaleEffect(controller.isDragging ? 0.985 : 1)
                .animation(.easeOut(duration: 0.12), value: controller.isDragging)
                .accessibilityLabel("Select")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Click wheel")
    }

    @ViewBuilder
    private var wheelRing: some View {
        if let image = DeviceAsset.image(named: "KurukuruWheelRing", extension: "png") {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.12), radius: 0.8, y: 0.35)
                .allowsHitTesting(false)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.94), Color(white: 0.89)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay { Circle().strokeBorder(.black.opacity(0.13), lineWidth: 0.7) }
                .shadow(color: .black.opacity(0.12), radius: 0.8, y: 0.35)
        }
    }

    @ViewBuilder
    private var centerButton: some View {
        if let image = DeviceAsset.image(named: "KurukuruCenterButton", extension: "png") {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.08), radius: 0.5, y: 0.25)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.72), Color(white: 0.61)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Circle().stroke(.white.opacity(0.30), lineWidth: 0.7))
                .overlay(Circle().stroke(.black.opacity(0.17), lineWidth: 0.6))
        }
    }

    private func wheelButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .foregroundStyle(Color(white: 0.40))
    }

    private func wheelButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9.5, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(white: 0.40))
    }

    private func perform(_ command: DeviceCommand) {
        controller.buttonPress()
        onCommand(command)
    }

    private func angle(for point: CGPoint, center: CGPoint) -> Double {
        atan2(point.y - center.y, point.x - center.x) * 180 / .pi
    }
}
