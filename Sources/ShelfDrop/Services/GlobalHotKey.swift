import Carbon.HIToolbox
import Foundation
import OSLog

private let shortcutLogger = Logger(
    subsystem: "work.hayashigoto.ShelfDrop",
    category: "Shortcuts"
)

final class GlobalHotKey {
    private static let identifier = EventHotKeyID(signature: 0x53484450, id: 1)

    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?
    private let action: () -> Void

    init?(optionTabAction action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, context in
                guard let context else { return OSStatus(eventNotHandledErr) }
                Unmanaged<GlobalHotKey>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                    .performAction()
                return noErr
            },
            1,
            &eventType,
            context,
            &eventHandlerReference
        )

        guard handlerStatus == noErr else { return nil }

        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_Tab),
            UInt32(optionKey),
            Self.identifier,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard registrationStatus == noErr else {
            if let eventHandlerReference {
                RemoveEventHandler(eventHandlerReference)
                self.eventHandlerReference = nil
            }
            return nil
        }
    }

    deinit {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
        }
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
    }

    private func performAction() {
        shortcutLogger.info("Option-Tab received")
        DispatchQueue.main.async {
            self.action()
        }
    }
}
