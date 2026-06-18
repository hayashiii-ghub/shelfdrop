import SwiftUI

struct ShelfItemDropDelegate: DropDelegate {
    let targetItemID: UUID
    @Binding var draggingItemID: UUID?
    let moveItem: (UUID, UUID) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingItemID, draggingItemID != targetItemID else { return }
        moveItem(draggingItemID, targetItemID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        return true
    }
}
