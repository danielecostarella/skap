import Foundation

public struct SkapSettings: Sendable, Equatable {
    public var showsCaptureHUD: Bool

    public init(showsCaptureHUD: Bool = true) {
        self.showsCaptureHUD = showsCaptureHUD
    }
}

public struct SkapSettingsStore {
    private let userDefaults: UserDefaults
    private let showsCaptureHUDKey = "showsCaptureHUD"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var settings: SkapSettings {
        get {
            SkapSettings(
                showsCaptureHUD: userDefaults.object(forKey: showsCaptureHUDKey) as? Bool ?? true
            )
        }
        nonmutating set {
            userDefaults.set(newValue.showsCaptureHUD, forKey: showsCaptureHUDKey)
        }
    }
}
