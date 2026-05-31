import CoreGraphics
import Foundation
import SkapCore

@MainActor
final class SkapAppModel: ObservableObject {
    @Published var lastCapture: CapturedImage?
    @Published var statusMessage = "Ready"
    @Published private(set) var hasSavedArea = false

    private let coordinator = SkapCoordinator()
    private let areaSelectionController = AreaSelectionController()
    private let windowSelectionController = WindowSelectionController()
    private let captureFeedbackController = CaptureFeedbackController()
    private let savedAreaStore = SavedCaptureAreaStore()
    private let shortcutController = GlobalShortcutController()

    init() {
        hasSavedArea = savedAreaStore.savedArea != nil

        shortcutController.onCaptureRequested = { [weak self] in
            Task { await self?.captureScreen() }
        }
    }

    func captureScreen() async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .screen)
            )
            lastCapture = image
            statusMessage = "Captured to clipboard"
            captureFeedbackController.show(image: image, message: statusMessage)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func beginAreaCapture() {
        statusMessage = "Select an area"
        areaSelectionController.beginSelection { [weak self] pixelRect in
            self?.saveArea(pixelRect)
            Task { await self?.captureArea(pixelRect, message: "Captured area to clipboard") }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    func captureSavedArea() {
        guard let savedArea = savedAreaStore.savedArea else {
            statusMessage = "No saved area yet"
            return
        }

        Task { await captureArea(savedArea, message: "Captured same area to clipboard") }
    }

    func beginWindowCapture() {
        statusMessage = "Click a window"
        windowSelectionController.beginSelection { [weak self] windowID in
            Task { await self?.captureWindow(windowID) }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    private func captureWindow(_ windowID: CGWindowID) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .window(.id(windowID)))
            )
            lastCapture = image
            statusMessage = "Captured window to clipboard"
            captureFeedbackController.show(image: image, message: statusMessage)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func captureArea(_ pixelRect: CGRect, message: String) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .area(pixelRect))
            )
            lastCapture = image
            statusMessage = message
            captureFeedbackController.show(image: image, message: statusMessage)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func saveArea(_ pixelRect: CGRect) {
        savedAreaStore.savedArea = pixelRect
        hasSavedArea = true
    }
}
