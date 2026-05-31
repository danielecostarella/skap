import Carbon
import Foundation
import SkapCore

@MainActor
final class GlobalShortcutController {
    var onCaptureScreenRequested: (() -> Void)?
    var onCaptureAreaRequested: (() -> Void)?
    var onCaptureSameAreaRequested: (() -> Void)?
    var onCaptureWindowRequested: (() -> Void)?
    var onCaptureAllDisplaysRequested: (() -> Void)?

    private enum ShortcutID: UInt32 {
        case captureScreen = 1
        case captureArea = 2
        case captureSameArea = 3
        case captureWindow = 4
        case captureAllDisplays = 5
    }

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [ShortcutID: EventHotKeyRef] = [:]

    init(shortcuts: [ShortcutAction: ShortcutConfig] = ShortcutConfig.defaults) {
        installEventHandler()
        registerShortcuts(from: shortcuts)
    }

    func updateShortcut(action: ShortcutAction, config: ShortcutConfig) {
        let id = shortcutID(for: action)
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: id)
        }
        registerShortcut(keyCode: config.keyCode, modifiers: config.modifiers, id: id)
    }

    private func registerShortcuts(from shortcuts: [ShortcutAction: ShortcutConfig]) {
        for (action, config) in shortcuts {
            let id = shortcutID(for: action)
            registerShortcut(keyCode: config.keyCode, modifiers: config.modifiers, id: id)
        }
    }

    private func registerShortcut(keyCode: UInt32, modifiers: UInt32, id: ShortcutID) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(
            signature: fourCharacterCode("SKAP"),
            id: id.rawValue
        )

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let hotKeyRef {
            hotKeyRefs[id] = hotKeyRef
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

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

                guard status == noErr else { return status }

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

    private func handleShortcut(id: UInt32) {
        switch ShortcutID(rawValue: id) {
        case .captureScreen:      onCaptureScreenRequested?()
        case .captureArea:        onCaptureAreaRequested?()
        case .captureSameArea:    onCaptureSameAreaRequested?()
        case .captureWindow:      onCaptureWindowRequested?()
        case .captureAllDisplays: onCaptureAllDisplaysRequested?()
        case nil: break
        }
    }

    private func shortcutID(for action: ShortcutAction) -> ShortcutID {
        switch action {
        case .captureScreen:      .captureScreen
        case .captureArea:        .captureArea
        case .captureSameArea:    .captureSameArea
        case .captureWindow:      .captureWindow
        case .captureAllDisplays: .captureAllDisplays
        }
    }

    private func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}
