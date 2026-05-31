import CoreGraphics
import Foundation
import SkapCore

@MainActor
final class SkapAppModel: ObservableObject {
    @Published var lastCapture: CapturedImage?
    @Published var statusMessage = "Ready"
    @Published private(set) var hasSavedArea = false
    @Published private(set) var savedAreaSummary = "No saved area"
    @Published private(set) var screenRecordingPermissionSummary = "Unknown"

    private let coordinator = SkapCoordinator()
    private let areaSelectionController = AreaSelectionController()
    private let windowSelectionController = WindowSelectionController()
    private let captureFeedbackController = CaptureFeedbackController()
    private let savedAreaStore = SavedCaptureAreaStore()
    private let shortcutController = GlobalShortcutController()

    init() {
        refreshSavedAreaState()
        refreshPermissionState()

        shortcutController.onCaptureScreenRequested = { [weak self] in
            Task { await self?.captureScreen() }
        }
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
        guard screenRecordingPermissionIsGranted() else {
            return
        }

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
        guard screenRecordingPermissionIsGranted() else {
            return
        }

        statusMessage = "Select an area"
        areaSelectionController.beginSelection { [weak self] pixelRect in
            self?.saveArea(pixelRect)
            Task { await self?.captureArea(pixelRect, message: "Captured area to clipboard") }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    func captureSavedArea() {
        guard screenRecordingPermissionIsGranted() else {
            return
        }

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
        guard screenRecordingPermissionIsGranted() else {
            return
        }

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

    func requestScreenRecordingPermission() {
        if ScreenRecordingPermission.request() {
            statusMessage = "Screen recording permission granted"
        } else {
            statusMessage = "Enable Screen Recording in System Settings"
        }
        refreshPermissionState()
    }

    func openScreenRecordingSettings() {
        ScreenRecordingPermission.openSystemSettings()
        statusMessage = "Opened Screen Recording settings"
    }

    func refreshPermissionState() {
        screenRecordingPermissionSummary = ScreenRecordingPermission.isGranted ? "Granted" : "Not granted"
    }

    private func captureArea(_ area: CaptureArea, message: String) async {
        do {
            let image = try await coordinator.capture(
                options: CaptureOptions(mode: .area(area))
            )
            lastCapture = image
            statusMessage = message
            captureFeedbackController.show(image: image, message: statusMessage)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func saveArea(_ area: CaptureArea) {
        savedAreaStore.savedArea = area
        refreshSavedAreaState()
    }

    private func screenRecordingPermissionIsGranted() -> Bool {
        refreshPermissionState()

        guard ScreenRecordingPermission.isGranted else {
            statusMessage = "Screen recording permission required"
            return false
        }

        return true
    }

    private func refreshSavedAreaState() {
        guard let savedArea = savedAreaStore.savedArea else {
            hasSavedArea = false
            savedAreaSummary = "No saved area"
            return
        }

        hasSavedArea = true
        savedAreaSummary = "\(Int(savedArea.pixelRect.width)) x \(Int(savedArea.pixelRect.height)) px on display \(savedArea.displayID)"
    }
}
