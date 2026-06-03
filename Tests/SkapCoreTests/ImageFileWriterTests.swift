import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import SkapCore

@Test func imageFileWriterWritesPNGAndJPEG() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let image = try testImage(width: 16, height: 12)
    let writer = ImageFileWriter()
    let pngURL = directory.appendingPathComponent("shot.png")
    let jpegURL = directory.appendingPathComponent("shot.jpg")

    try writer.write(image, to: pngURL, format: .png, jpegQuality: 0.85)
    try writer.write(image, to: jpegURL, format: .jpeg, jpegQuality: 0.5)

    #expect(CGImageSourceCreateWithURL(pngURL as CFURL, nil) != nil)
    #expect(CGImageSourceCreateWithURL(jpegURL as CFURL, nil) != nil)
}

@Test func imageFileWriterRejectsInvalidDestination() throws {
    let image = try testImage(width: 8, height: 8)
    let invalidURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("missing")
        .appendingPathComponent("shot.png")

    #expect(throws: ImageFileWriterError.self) {
        try ImageFileWriter().write(image, to: invalidURL, format: .png, jpegQuality: 0.85)
    }
}

private func testImage(width: Int, height: Int) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw TestImageError.cannotCreateContext
    }

    context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let image = context.makeImage() else {
        throw TestImageError.cannotCreateImage
    }
    return image
}

private enum TestImageError: Error {
    case cannotCreateContext
    case cannotCreateImage
}
