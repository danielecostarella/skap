import Foundation

public enum ShortcutAction: String, Codable, CaseIterable, Sendable {
    case captureScreen
    case captureArea
    case captureSameArea
    case captureWindow
    case captureAllDisplays
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
        .captureScreen:       ShortcutConfig(keyCode: 18, modifiers: cmdShift), // ⌘⇧1
        .captureArea:         ShortcutConfig(keyCode: 19, modifiers: cmdShift), // ⌘⇧2
        .captureSameArea:     ShortcutConfig(keyCode: 20, modifiers: cmdShift), // ⌘⇧3
        .captureWindow:       ShortcutConfig(keyCode: 21, modifiers: cmdShift), // ⌘⇧4
        .captureAllDisplays:  ShortcutConfig(keyCode: 23, modifiers: cmdShift), // ⌘⇧5
    ]
}
