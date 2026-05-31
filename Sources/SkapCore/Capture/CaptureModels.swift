import CoreGraphics
import Foundation

public enum CaptureMode: Sendable, Equatable {
    case screen
    case window(WindowSelection)
    case area(CaptureArea)
}

public struct CaptureArea: Codable, Sendable, Equatable {
    public var displayID: CGDirectDisplayID
    public var pixelRect: CGRect

    public init(displayID: CGDirectDisplayID, pixelRect: CGRect) {
        self.displayID = displayID
        self.pixelRect = pixelRect
    }
}

public enum WindowSelection: Sendable, Equatable {
    case current
    case id(CGWindowID)
}

public struct CaptureOptions: Sendable, Equatable {
    public var mode: CaptureMode
    public var copyToClipboard: Bool
    public var outputURL: URL?
    public var pinAfterCapture: Bool

    public init(
        mode: CaptureMode,
        copyToClipboard: Bool = true,
        outputURL: URL? = nil,
        pinAfterCapture: Bool = false
    ) {
        self.mode = mode
        self.copyToClipboard = copyToClipboard
        self.outputURL = outputURL
        self.pinAfterCapture = pinAfterCapture
    }
}

public struct CapturedImage: Sendable {
    public var cgImage: CGImage
    public var metadata: CaptureMetadata

    public init(cgImage: CGImage, metadata: CaptureMetadata) {
        self.cgImage = cgImage
        self.metadata = metadata
    }
}

public struct CaptureMetadata: Sendable, Equatable {
    public var modeDescription: String
    public var scale: CGFloat
    public var createdAt: Date

    public init(modeDescription: String, scale: CGFloat = 1, createdAt: Date = .now) {
        self.modeDescription = modeDescription
        self.scale = scale
        self.createdAt = createdAt
    }
}
