import CoreGraphics
import Darwin
import Foundation
@preconcurrency import ScreenCaptureKit

public protocol ScreenCapturing: Sendable {
    func capture(options: CaptureOptions) async throws -> CapturedImage
}

public enum CaptureError: LocalizedError, Sendable {
    case permissionDenied
    case noDisplayAvailable
    case noWindowAvailable
    case unsupportedMode(String)
    case imageCreationFailed

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Screen recording permission is required."
        case .noDisplayAvailable:
            "No display is available for capture."
        case .noWindowAvailable:
            "No matching window is available for capture."
        case .unsupportedMode(let mode):
            "Capture mode is not implemented yet: \(mode)."
        case .imageCreationFailed:
            "Could not create an image from the captured content."
        }
    }
}

public actor ScreenCaptureKitCaptureService: ScreenCapturing {
    public init() {}

    public func capture(options: CaptureOptions) async throws -> CapturedImage {
        switch options.mode {
        case .screen(let selection):
            return try await captureScreen(selection)
        case .window(.current):
            return try await captureWindow(try currentWindowID())
        case .window(.id(let windowID)):
            return try await captureWindow(windowID)
        case .area(let area):
            return try await captureArea(area)
        }
    }

    private func captureScreen(_ selection: ScreenSelection) async throws -> CapturedImage {
        let image: CGImage
        let modeDescription: String

        switch selection {
        case .main:
            image = try await captureMainDisplayImage()
            modeDescription = "screen"
        case .display(let displayID):
            image = try await captureDisplayImage(displayID: displayID)
            modeDescription = "display"
        case .all:
            image = try await captureAllDisplayImage()
            modeDescription = "all-displays"
        }

        return CapturedImage(
            cgImage: image,
            metadata: CaptureMetadata(modeDescription: modeDescription)
        )
    }

    private func captureArea(_ area: CaptureArea) async throws -> CapturedImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == area.displayID }) else {
            throw CaptureError.noDisplayAvailable
        }

        // Capture at physical pixel resolution so pixelRect (scaled by backingScaleFactor) is valid.
        let image = try await captureDisplayImage(display: display, scale: area.scale)

        let boundedRect = area.pixelRect.integral.intersection(
            CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )

        guard
            boundedRect.width > 0,
            boundedRect.height > 0,
            let croppedImage = image.cropping(to: boundedRect)
        else {
            throw CaptureError.imageCreationFailed
        }

        return CapturedImage(
            cgImage: croppedImage,
            metadata: CaptureMetadata(modeDescription: "area")
        )
    }

    private func captureWindow(_ windowID: CGWindowID) async throws -> CapturedImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )

        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw CaptureError.noWindowAvailable
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        configuration.width = Int(filter.contentRect.width * scale)
        configuration.height = Int(filter.contentRect.height * scale)
        configuration.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )

        return CapturedImage(
            cgImage: image,
            metadata: CaptureMetadata(modeDescription: "window")
        )
    }

    private nonisolated func currentWindowID() throws -> CGWindowID {
        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            throw CaptureError.noWindowAvailable
        }

        for info in windowInfo {
            guard
                let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0,
                let alpha = info[kCGWindowAlpha as String] as? Double,
                alpha > 0,
                let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                ownerPID != getpid()
            else {
                continue
            }

            return windowID
        }

        throw CaptureError.noWindowAvailable
    }

    private func captureMainDisplayImage() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        let mainID = CGMainDisplayID()
        guard let display = content.displays.first(where: { $0.displayID == mainID })
                             ?? content.displays.first else {
            throw CaptureError.noDisplayAvailable
        }

        return try await captureDisplayImage(display: display)
    }

    private func captureAllDisplayImage() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard !content.displays.isEmpty else {
            throw CaptureError.noDisplayAvailable
        }

        var captures: [DisplayCapture] = []
        for display in content.displays {
            let image = try await captureDisplayImage(display: display)
            captures.append(DisplayCapture(display: display, image: image))
        }

        return try stitchDisplayCaptures(captures)
    }

    private func captureDisplayImage(displayID: CGDirectDisplayID) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplayAvailable
        }

        return try await captureDisplayImage(display: display)
    }

    private func captureDisplayImage(display: SCDisplay, scale: CGFloat = 1) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = Int((CGFloat(display.width) * scale).rounded())
        configuration.height = Int((CGFloat(display.height) * scale).rounded())
        configuration.showsCursor = true

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
    }

    private nonisolated func stitchDisplayCaptures(_ captures: [DisplayCapture]) throws -> CGImage {
        let unionFrame = captures
            .map(\.display.frame)
            .reduce(CGRect.null) { $0.union($1) }
            .integral

        guard
            unionFrame.width > 0,
            unionFrame.height > 0,
            let context = CGContext(
                data: nil,
                width: Int(unionFrame.width),
                height: Int(unionFrame.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw CaptureError.imageCreationFailed
        }

        context.setFillColor(CGColor(gray: 0, alpha: 0))
        context.fill(CGRect(origin: .zero, size: unionFrame.size))

        for capture in captures {
            let frame = capture.display.frame
            let drawRect = CGRect(
                x: frame.minX - unionFrame.minX,
                y: unionFrame.maxY - frame.maxY,
                width: frame.width,
                height: frame.height
            )
            context.draw(capture.image, in: drawRect)
        }

        guard let stitchedImage = context.makeImage() else {
            throw CaptureError.imageCreationFailed
        }

        return stitchedImage
    }
}

private struct DisplayCapture {
    let display: SCDisplay
    let image: CGImage
}
