import Foundation

public enum ImageFormat: String, Codable, CaseIterable, Sendable {
    case png
    case jpeg

    public var fileExtension: String { rawValue }

    public var displayName: String {
        switch self {
        case .png: "PNG"
        case .jpeg: "JPEG"
        }
    }
}
