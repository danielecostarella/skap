import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public protocol ImageFileWriting: Sendable {
    func write(_ image: CGImage, to url: URL, format: ImageFormat) throws
}

public enum ImageFileWriterError: LocalizedError, Sendable {
    case cannotCreateDestination(URL)
    case cannotFinalize(URL)

    public var errorDescription: String? {
        switch self {
        case .cannotCreateDestination(let url):
            "Cannot create an image destination at \(url.path)."
        case .cannotFinalize(let url):
            "Cannot write the image file at \(url.path)."
        }
    }
}

public struct ImageFileWriter: ImageFileWriting {
    public init() {}

    public func write(_ image: CGImage, to url: URL, format: ImageFormat) throws {
        let utType: UTType = format == .png ? .png : .jpeg

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageFileWriterError.cannotCreateDestination(url)
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageFileWriterError.cannotFinalize(url)
        }
    }
}
