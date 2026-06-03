import Foundation
import Testing
@testable import SkapCore

@Test func settingsStorePersistsCaptureHUDPreference() {
    let suiteName = "skap-settings-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let store = SkapSettingsStore(userDefaults: defaults)

    #expect(store.settings.showsCaptureHUD)

    store.settings = SkapSettings(showsCaptureHUD: false)

    #expect(!store.settings.showsCaptureHUD)
}

@Test func settingsStorePersistsAllCapturePreferences() {
    let suiteName = "skap-settings-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let folder = URL(fileURLWithPath: "/tmp/skap-tests")
    let shortcuts: [ShortcutAction: ShortcutConfig] = [
        .captureScreen: ShortcutConfig(keyCode: 12, modifiers: 768),
        .captureArea: ShortcutConfig(keyCode: 13, modifiers: 768),
    ]
    let store = SkapSettingsStore(userDefaults: defaults)
    store.settings = SkapSettings(
        showsCaptureHUD: false,
        copyToClipboard: false,
        saveToFile: true,
        defaultSaveFolder: folder,
        imageFormat: .jpeg,
        jpegQuality: 0.7,
        captureSound: true,
        shortcuts: shortcuts
    )

    let loaded = store.settings

    #expect(!loaded.showsCaptureHUD)
    #expect(!loaded.copyToClipboard)
    #expect(loaded.saveToFile)
    #expect(loaded.defaultSaveFolder == folder)
    #expect(loaded.imageFormat == .jpeg)
    #expect(loaded.jpegQuality == 0.7)
    #expect(loaded.captureSound)
    #expect(loaded.shortcuts[.captureScreen] == shortcuts[.captureScreen])
    #expect(loaded.shortcuts[.captureArea] == shortcuts[.captureArea])
}

@Test func settingsStoreClampsJPEGQuality() {
    let suiteName = "skap-settings-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer {
        defaults.removePersistentDomain(forName: suiteName)
    }

    let store = SkapSettingsStore(userDefaults: defaults)
    store.settings = SkapSettings(jpegQuality: 1.5)

    #expect(store.settings.jpegQuality == 1)
}
