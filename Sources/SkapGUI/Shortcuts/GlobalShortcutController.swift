import Carbon
import Foundation

@MainActor
final class GlobalShortcutController {
    var onCaptureScreenRequested: (() -> Void)?
    var onCaptureAreaRequested: (() -> Void)?
    var onCaptureSameAreaRequested: (() -> Void)?
    var onCaptureWindowRequested: (() -> Void)?

    private enum ShortcutID: UInt32 {
        case captureScreen = 1
        case captureArea = 2
        case captureSameArea = 3
        case captureWindow = 4
    }

    private var eventHandler: EventHandlerRef?
    private var hotKeys: [EventHotKeyRef] = []

    init() {
        installEventHandler()
        registerDefaultShortcuts()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return status
                }

                let controller = Unmanaged<GlobalShortcutController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                Task { @MainActor in
                    controller.handleShortcut(id: hotKeyID.id)
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    private func registerDefaultShortcuts() {
        registerShortcut(keyCode: 18, id: .captureScreen)
        registerShortcut(keyCode: 19, id: .captureArea)
        registerShortcut(keyCode: 20, id: .captureSameArea)
        registerShortcut(keyCode: 21, id: .captureWindow)
    }

    private func registerShortcut(keyCode: UInt32, id: ShortcutID) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(
            signature: fourCharacterCode("SKAP"),
            id: id.rawValue
        )

        let status = RegisterEventHotKey(
            keyCode,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let hotKeyRef {
            hotKeys.append(hotKeyRef)
        }
    }

    private func handleShortcut(id: UInt32) {
        switch ShortcutID(rawValue: id) {
        case .captureScreen:
            onCaptureScreenRequested?()
        case .captureArea:
            onCaptureAreaRequested?()
        case .captureSameArea:
            onCaptureSameAreaRequested?()
        case .captureWindow:
            onCaptureWindowRequested?()
        case nil:
            break
        }
    }

    private func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { partialResult, character in
            (partialResult << 8) + OSType(character)
        }
    }
}
