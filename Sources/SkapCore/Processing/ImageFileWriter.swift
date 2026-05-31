import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public protocol ImageFileWriting: Sendable {
    func writePNG(_ image: CGImage, to url: URL) throws
}

public enum ImageFileWriterError: LocalizedError, Sendable {
    case cannotCreateDestination(URL)
    case cannotFinalize(URL)

    public var errorDescription: String? {
        switch self {
        case .cannotCreateDestination(let url):
            "Cannot create an image destination at \(url.path)."
        case .cannotFinalize(let url):
            "Cannot write the PNG file at \(url.path)."
        }
    }
}

public struct PNGImageFileWriter: ImageFileWriting {
    public init() {}

    public func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
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
