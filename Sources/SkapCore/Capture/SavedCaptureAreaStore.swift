import CoreGraphics
import Foundation

public struct SavedCaptureAreaStore {
    private let fileURL: URL

    public init(fileURL: URL = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public var savedArea: CaptureArea? {
        get {
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }

            if let captureArea = try? JSONDecoder().decode(CaptureArea.self, from: data) {
                return captureArea
            }

            if let legacyRect = try? JSONDecoder().decode(CGRect.self, from: data) {
                return CaptureArea(displayID: CGMainDisplayID(), pixelRect: legacyRect)
            }

            return nil
        }
        nonmutating set {
            guard let newValue else {
                try? FileManager.default.removeItem(at: fileURL)
                return
            }

            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }

            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    public static func defaultFileURL() -> URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser

        return baseURL
            .appendingPathComponent("skap", isDirectory: true)
            .appendingPathComponent("saved-area.json")
    }
}
