import CoreGraphics
import Foundation

struct SavedCaptureAreaStore {
    private let key = "savedCaptureArea"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var savedArea: CGRect? {
        get {
            guard let data = userDefaults.data(forKey: key) else {
                return nil
            }

            return try? JSONDecoder().decode(CGRect.self, from: data)
        }
        nonmutating set {
            guard let newValue else {
                userDefaults.removeObject(forKey: key)
                return
            }

            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }

            userDefaults.set(data, forKey: key)
        }
    }
}
