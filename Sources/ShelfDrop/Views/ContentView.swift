import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var presentation: DopaGakPresentationState
    let onCommand: (DeviceCommand) -> Void

    var body: some View {
        ZStack {
            Color.clear

            Group {
                switch presentation.deviceStyle {
                case .kurukuru:
                    KurukuruDeviceView(
                        store: store,
                        presentation: presentation,
                        onCommand: onCommand
                    )
                case .pochitto:
                    PochittoDeviceView(
                        store: store,
                        presentation: presentation,
                        onCommand: onCommand
                    )
                }
            }
            .padding(DeviceMetrics.windowInset)
        }
        .frame(
            width: presentation.deviceStyle.metrics.panelSize.width,
            height: presentation.deviceStyle.metrics.panelSize.height
        )
    }
}
