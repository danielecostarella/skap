import CoreGraphics
import Foundation
import SkapCore

@MainActor
final class SkapAppModel: ObservableObject {
    @Published var lastCapture: CapturedImage?
    @Published var statusMessage = "Ready"
    @Published private(set) var hasSavedArea = false
    @Published private(set) var savedAreaSummary = "No saved area"

    private let coordinator = SkapCoordinator()
    private let areaSelectionController = AreaSelectionController()
    private let windowSelectionController = WindowSelectionController()
    private let captureFeedbackController = CaptureFeedbackController()
    private let savedAreaStore = SavedCaptureAreaStore()
    private let shortcutController = GlobalShortcutController()

    init() {
        refreshSavedAreaState()

        shortcutController.onCaptureAreaRequested = { [weak self] in
            self?.beginAreaCapture()
        }
        shortcutController.onCaptureSameAreaRequested = { [weak self] in
            self?.captureSavedArea()
        }
        shortcutController.onCaptureWindowRequested = { [weak self] in
            self?.beginWindowCapture()
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

    func clearSavedArea() {
        savedAreaStore.savedArea = nil
        refreshSavedAreaState()
        statusMessage = "Saved area cleared"
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
        refreshSavedAreaState()
    }

    private func refreshSavedAreaState() {
        guard let savedArea = savedAreaStore.savedArea else {
            hasSavedArea = false
            savedAreaSummary = "No saved area"
            return
        }

        hasSavedArea = true
        savedAreaSummary = "\(Int(savedArea.width)) x \(Int(savedArea.height)) px at \(Int(savedArea.minX)), \(Int(savedArea.minY))"
    }
}
