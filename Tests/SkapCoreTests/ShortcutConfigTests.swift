import Foundation
import Testing
@testable import SkapCore

@Test func shortcutConfigRoundTripsThroughJSON() throws {
    let shortcuts: [ShortcutAction: ShortcutConfig] = [
        .captureScreen: ShortcutConfig(keyCode: 18, modifiers: 768),
        .captureWindow: ShortcutConfig(keyCode: 21, modifiers: 768),
    ]
    let encoded = try JSONEncoder().encode(shortcuts)
    let decoded = try JSONDecoder().decode([ShortcutAction: ShortcutConfig].self, from: encoded)

    #expect(decoded == shortcuts)
}

@Test func shortcutDefaultsContainEveryAction() {
    for action in ShortcutAction.allCases {
        #expect(ShortcutConfig.defaults[action] != nil)
    }
}
