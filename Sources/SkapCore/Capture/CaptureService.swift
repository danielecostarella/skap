import CoreGraphics
import Foundation
import ScreenCaptureKit

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
        case .screen:
            return try await captureMainDisplay()
        case .window(.current):
            throw CaptureError.unsupportedMode("current window")
        case .window(.id(let windowID)):
            return try await captureWindow(windowID)
        case .area(let area):
            return try await captureArea(area)
        }
    }

    private func captureMainDisplay() async throws -> CapturedImage {
        let image = try await captureMainDisplayImage()

        return CapturedImage(
            cgImage: image,
            metadata: CaptureMetadata(modeDescription: "screen")
        )
    }

    private func captureArea(_ area: CaptureArea) async throws -> CapturedImage {
        let image = try await captureDisplayImage(displayID: area.displayID)
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

    private func captureMainDisplayImage() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let display = content.displays.first else {
            throw CaptureError.noDisplayAvailable
        }

        return try await captureDisplayImage(display: display)
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

    private func captureDisplayImage(display: SCDisplay) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.showsCursor = true

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
    }
}
