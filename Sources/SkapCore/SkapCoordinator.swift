import CoreGraphics
import Foundation

public actor SkapCoordinator {
    private let captureService: any ScreenCapturing
    private let clipboardWriter: any ClipboardWriting
    private let fileWriter: any ImageFileWriting

    public init(
        captureService: any ScreenCapturing = ScreenCaptureKitCaptureService(),
        clipboardWriter: any ClipboardWriting = PasteboardClipboardWriter(),
        fileWriter: any ImageFileWriting = PNGImageFileWriter()
    ) {
        self.captureService = captureService
        self.clipboardWriter = clipboardWriter
        self.fileWriter = fileWriter
    }

    @discardableResult
    public func capture(options: CaptureOptions) async throws -> CapturedImage {
        let image = try await captureService.capture(options: options)

        if options.copyToClipboard {
            await clipboardWriter.write(image.cgImage)
        }

        if let outputURL = options.outputURL {
            try fileWriter.writePNG(image.cgImage, to: outputURL)
        }

        return image
    }
}
