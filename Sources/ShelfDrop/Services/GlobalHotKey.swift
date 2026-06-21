import Carbon.HIToolbox
import Foundation
import OSLog

private let shortcutLogger = Logger(
    subsystem: "work.hayashigoto.ShelfDrop",
    category: "Shortcuts"
)

enum ShelfShortcut {
    case addFinderSelection
    case toggleShelf

    private static let signature: OSType = 0x53484450

    var keyCode: UInt32 {
        UInt32(kVK_Tab)
    }

    var modifiers: UInt32 {
        switch self {
        case .addFinderSelection:
            UInt32(optionKey)
        case .toggleShelf:
            UInt32(optionKey | shiftKey)
        }
    }

    var identifier: EventHotKeyID {
        switch self {
        case .addFinderSelection:
            EventHotKeyID(signature: Self.signature, id: 1)
        case .toggleShelf:
            EventHotKeyID(signature: Self.signature, id: 2)
        }
    }

    var logName: String {
        switch self {
        case .addFinderSelection:
            "Option-Tab"
        case .toggleShelf:
            "Option-Shift-Tab"
        }
    }

    func matches(_ identifier: EventHotKeyID) -> Bool {
        let expected = self.identifier
        return identifier.signature == expected.signature && identifier.id == expected.id
    }
}

final class GlobalHotKey {
    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?
    private let shortcut: ShelfShortcut
    private let action: () -> Void

    init?(shortcut: ShelfShortcut, action: @escaping () -> Void) {
        self.shortcut = shortcut
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<GlobalHotKey>
                    .fromOpaque(context)
                    .takeUnretainedValue()

                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard status == noErr, hotKey.shortcut.matches(identifier) else {
                    return OSStatus(eventNotHandledErr)
                }

                hotKey.performAction()
                return noErr
            },
            1,
            &eventType,
            context,
            &eventHandlerReference
        )

        guard handlerStatus == noErr else { return nil }

        let registrationStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            shortcut.identifier,
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
        shortcutLogger.info("\(self.shortcut.logName, privacy: .public) received")
        DispatchQueue.main.async {
            self.action()
        }
    }
}
