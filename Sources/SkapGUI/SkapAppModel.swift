import CoreGraphics
import Foundation
import SkapCore

@MainActor
final class SkapAppModel: ObservableObject {
    @Published var lastCapture: CapturedImage?
    @Published var statusMessage = "Ready"

    private let coordinator = SkapCoordinator()
    private let pinController = PinWindowController()
    private let areaSelectionController = AreaSelectionController()
    private let windowSelectionController = WindowSelectionController()
    private let captureFeedbackController = CaptureFeedbackController()
    private let shortcutController = GlobalShortcutController()

    init() {
        shortcutController.onCaptureRequested = { [weak self] in
            Task { await self?.captureScreen() }
        }
    }

    func captureScreen(pin: Bool = false) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .screen, pinAfterCapture: pin)
            )
            lastCapture = image
            statusMessage = "Captured to clipboard"
            captureFeedbackController.show(image: image, message: statusMessage)

            if pin {
                pinController.pin(image: image)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func beginAreaCapture(pin: Bool = false) {
        statusMessage = "Select an area"
        areaSelectionController.beginSelection { [weak self] pixelRect in
            Task { await self?.captureArea(pixelRect, pin: pin) }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    func beginWindowCapture(pin: Bool = false) {
        statusMessage = "Click a window"
        windowSelectionController.beginSelection { [weak self] windowID in
            Task { await self?.captureWindow(windowID, pin: pin) }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    private func captureWindow(_ windowID: CGWindowID, pin: Bool) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .window(.id(windowID)), pinAfterCapture: pin)
            )
            lastCapture = image
            statusMessage = pin ? "Captured window, copied, and pinned" : "Captured window to clipboard"
            captureFeedbackController.show(image: image, message: statusMessage)

            if pin {
                pinController.pin(image: image)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func captureArea(_ pixelRect: CGRect, pin: Bool) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .area(pixelRect), pinAfterCapture: pin)
            )
            lastCapture = image
            statusMessage = pin ? "Captured, copied, and pinned" : "Captured area to clipboard"
            captureFeedbackController.show(image: image, message: statusMessage)

            if pin {
                pinController.pin(image: image)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
