import Foundation

public enum ShortcutAction: String, Codable, CaseIterable, Sendable {
    case captureScreen
    case captureArea
    case captureSameArea
    case captureWindow
}

public struct ShortcutConfig: Codable, Sendable, Equatable {
    public var keyCode: UInt32
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    // Carbon: cmdKey=256, shiftKey=512 → 768
    private static let cmdShift: UInt32 = 768

    public static let defaults: [ShortcutAction: ShortcutConfig] = [
        .captureScreen:   ShortcutConfig(keyCode: 18, modifiers: cmdShift),
        .captureArea:     ShortcutConfig(keyCode: 19, modifiers: cmdShift),
        .captureSameArea: ShortcutConfig(keyCode: 20, modifiers: cmdShift),
        .captureWindow:   ShortcutConfig(keyCode: 21, modifiers: cmdShift),
    ]
}
