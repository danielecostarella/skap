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
