import SwiftUI

struct DeviceWindowDragSurface: View {
    var enablesWindowDrag = true

    var body: some View {
        Group {
            if enablesWindowDrag {
                WindowDragHandle()
            } else {
                Color.clear
            }
        }
        .contentShape(Rectangle())
    }
}
