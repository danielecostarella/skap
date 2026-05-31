import Foundation

public struct SkapSettings: Sendable, Equatable {
    public var showsCaptureHUD: Bool
    public var copyToClipboard: Bool
    public var saveToFile: Bool
    public var defaultSaveFolder: URL
    public var imageFormat: ImageFormat
    public var captureSound: Bool
    public var shortcuts: [ShortcutAction: ShortcutConfig]

    public init(
        showsCaptureHUD: Bool = true,
        copyToClipboard: Bool = true,
        saveToFile: Bool = false,
        defaultSaveFolder: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop"),
        imageFormat: ImageFormat = .png,
        captureSound: Bool = true,
        shortcuts: [ShortcutAction: ShortcutConfig] = ShortcutConfig.defaults
    ) {
        self.showsCaptureHUD = showsCaptureHUD
        self.copyToClipboard = copyToClipboard
        self.saveToFile = saveToFile
        self.defaultSaveFolder = defaultSaveFolder
        self.imageFormat = imageFormat
        self.captureSound = captureSound
        self.shortcuts = shortcuts
    }
}

public struct SkapSettingsStore {
    private let userDefaults: UserDefaults

    private enum Key {
        static let showsCaptureHUD = "showsCaptureHUD"
        static let copyToClipboard = "copyToClipboard"
        static let saveToFile = "saveToFile"
        static let defaultSaveFolder = "defaultSaveFolder"
        static let imageFormat = "imageFormat"
        static let captureSound = "captureSound"
        static let shortcuts = "shortcuts"
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var settings: SkapSettings {
        get {
            let shortcuts = loadShortcuts()
            let folder = loadSaveFolder()
            let format = ImageFormat(rawValue: userDefaults.string(forKey: Key.imageFormat) ?? "") ?? .png

            return SkapSettings(
                showsCaptureHUD: userDefaults.object(forKey: Key.showsCaptureHUD) as? Bool ?? true,
                copyToClipboard: userDefaults.object(forKey: Key.copyToClipboard) as? Bool ?? true,
                saveToFile: userDefaults.bool(forKey: Key.saveToFile),
                defaultSaveFolder: folder,
                imageFormat: format,
                captureSound: userDefaults.object(forKey: Key.captureSound) as? Bool ?? true,
                shortcuts: shortcuts
            )
        }
        nonmutating set {
            userDefaults.set(newValue.showsCaptureHUD, forKey: Key.showsCaptureHUD)
            userDefaults.set(newValue.copyToClipboard, forKey: Key.copyToClipboard)
            userDefaults.set(newValue.saveToFile, forKey: Key.saveToFile)
            userDefaults.set(newValue.defaultSaveFolder.path, forKey: Key.defaultSaveFolder)
            userDefaults.set(newValue.imageFormat.rawValue, forKey: Key.imageFormat)
            userDefaults.set(newValue.captureSound, forKey: Key.captureSound)
            saveShortcuts(newValue.shortcuts)
        }
    }

    private func loadShortcuts() -> [ShortcutAction: ShortcutConfig] {
        guard let data = userDefaults.data(forKey: Key.shortcuts),
              let decoded = try? JSONDecoder().decode([String: ShortcutConfig].self, from: data)
        else {
            return ShortcutConfig.defaults
        }
        var result = ShortcutConfig.defaults
        for (key, value) in decoded {
            if let action = ShortcutAction(rawValue: key) {
                result[action] = value
            }
        }
        return result
    }

    private func saveShortcuts(_ shortcuts: [ShortcutAction: ShortcutConfig]) {
        let stringKeyed = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(stringKeyed) {
            userDefaults.set(data, forKey: Key.shortcuts)
        }
    }

    private func loadSaveFolder() -> URL {
        if let path = userDefaults.string(forKey: Key.defaultSaveFolder) {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop")
    }
}
