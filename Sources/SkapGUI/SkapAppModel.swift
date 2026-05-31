import AppKit
import CoreGraphics
import Foundation
import SkapCore

@MainActor
final class SkapAppModel: ObservableObject {
    @Published var settings: SkapSettings {
        didSet {
            settingsStore.settings = settings
            updateChangedShortcuts(from: oldValue)
        }
    }
    @Published var lastCapture: CapturedImage?
    @Published var statusMessage = "Ready"
    @Published private(set) var hasSavedArea = false
    @Published private(set) var savedAreaSummary = "No saved area"
    @Published private(set) var screenRecordingPermissionSummary = "Unknown"

    private let coordinator = SkapCoordinator()
    private let clipboardWriter = PasteboardClipboardWriter()
    private var annotationEditorController: AnnotationEditorWindowController?
    private let areaSelectionController = AreaSelectionController()
    private let windowSelectionController = WindowSelectionController()
    private let captureFeedbackController = CaptureFeedbackController()
    private let onboardingController = OnboardingWindowController()
    private let savedAreaStore = SavedCaptureAreaStore()
    private let settingsStore: SkapSettingsStore
    private let shortcutController: GlobalShortcutController

    init() {
        let store = SkapSettingsStore()
        let stored = store.settings
        settingsStore = store
        settings = stored
        shortcutController = GlobalShortcutController(shortcuts: stored.shortcuts)

        refreshSavedAreaState()
        refreshPermissionState()

        Task { [weak self] in
            self?.onboardingController.showIfNeeded()
        }

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
        await captureScreen(.main)
    }

    func captureAllDisplays() async {
        await captureScreen(.all)
    }

    private func captureScreen(_ selection: ScreenSelection) async {
        guard screenRecordingPermissionIsGranted() else { return }

        do {
            let image = try await coordinator.capture(options: captureOptions(mode: .screen(selection)))
            lastCapture = image
            statusMessage = selection == .all ? "Captured all displays to clipboard" : "Captured to clipboard"
            showCaptureFeedback(image: image)
        } catch {
            statusMessage = error.localizedDescription
            showErrorFeedback(message: error.localizedDescription)
        }
    }

    func beginAreaCapture() {
        guard screenRecordingPermissionIsGranted() else { return }

        statusMessage = "Select an area"
        areaSelectionController.beginSelection { [weak self] pixelRect in
            self?.saveArea(pixelRect)
            Task { await self?.captureArea(pixelRect, message: "Captured area to clipboard") }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    func captureSavedArea() {
        guard screenRecordingPermissionIsGranted() else { return }

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
        guard screenRecordingPermissionIsGranted() else { return }

        statusMessage = "Click a window"
        windowSelectionController.beginSelection { [weak self] windowID in
            Task { await self?.captureWindow(windowID) }
        } onCancel: { [weak self] in
            self?.statusMessage = "Ready"
        }
    }

    private func captureWindow(_ windowID: CGWindowID) async {
        do {
            let image = try await coordinator.capture(options: captureOptions(mode: .window(.id(windowID))))
            lastCapture = image
            statusMessage = "Captured window to clipboard"
            showCaptureFeedback(image: image)
        } catch {
            statusMessage = error.localizedDescription
            showErrorFeedback(message: error.localizedDescription)
        }
    }

    func requestScreenRecordingPermission() {
        if ScreenRecordingPermission.request() {
            statusMessage = "Screen recording permission granted"
            refreshPermissionState()
        } else {
            statusMessage = "Enable Screen Recording in System Settings"
            startPermissionPolling()
        }
    }

    func openScreenRecordingSettings() {
        ScreenRecordingPermission.openSystemSettings()
        statusMessage = "Opened Screen Recording settings"
        startPermissionPolling()
    }

    func refreshPermissionState() {
        screenRecordingPermissionSummary = ScreenRecordingPermission.isGranted ? "Granted" : "Not granted"
    }

    private func captureArea(_ area: CaptureArea, message: String) async {
        do {
            let image = try await coordinator.capture(options: captureOptions(mode: .area(area)))
            lastCapture = image
            statusMessage = message
            showCaptureFeedback(image: image)
        } catch {
            statusMessage = error.localizedDescription
            showErrorFeedback(message: error.localizedDescription)
        }
    }

    private func saveArea(_ area: CaptureArea) {
        savedAreaStore.savedArea = area
        refreshSavedAreaState()
    }

    private func showCaptureFeedback(image: CapturedImage) {
        guard settings.showsCaptureHUD else { return }
        playCaptureSoundIfEnabled()
        captureFeedbackController.show(image: image, message: statusMessage)
    }

    private func showErrorFeedback(message: String) {
        guard settings.showsCaptureHUD else { return }
        captureFeedbackController.showError(message: message)
    }

    private func playCaptureSoundIfEnabled() {
        guard settings.captureSound else { return }
        (NSSound(named: .init("Tink")) ?? NSSound(named: .init("Pop")))?.play()
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
        savedAreaSummary = "\(Int(savedArea.pixelRect.width)) × \(Int(savedArea.pixelRect.height)) px — display \(savedArea.displayID)"
    }

    private func captureOptions(mode: CaptureMode) -> CaptureOptions {
        CaptureOptions(
            mode: mode,
            copyToClipboard: settings.copyToClipboard,
            outputURL: settings.saveToFile ? autoSaveURL() : nil,
            imageFormat: settings.imageFormat
        )
    }

    private func autoSaveURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let name = "Screenshot \(formatter.string(from: Date())).\(settings.imageFormat.fileExtension)"
        return settings.defaultSaveFolder.appendingPathComponent(name)
    }

    private func updateChangedShortcuts(from oldSettings: SkapSettings) {
        for action in ShortcutAction.allCases {
            let newConfig = settings.shortcuts[action]
            let oldConfig = oldSettings.shortcuts[action]
            if newConfig != oldConfig, let config = newConfig {
                shortcutController.updateShortcut(action: action, config: config)
            }
        }
    }

    func editLastCapture() {
        guard let capture = lastCapture else { return }
        annotationEditorController = AnnotationEditorWindowController(capturedImage: capture)
        annotationEditorController?.onDone = { [weak self] renderedImage in
            guard let self else { return }
            self.clipboardWriter.write(renderedImage)
            self.lastCapture = CapturedImage(
                cgImage: renderedImage,
                metadata: CaptureMetadata(modeDescription: "annotated")
            )
            self.statusMessage = "Annotated capture copied to clipboard"
        }
        annotationEditorController?.show()
    }

    private var permissionPollingTask: Task<Void, Never>?

    private func startPermissionPolling() {
        permissionPollingTask?.cancel()
        permissionPollingTask = Task { [weak self] in
            for _ in 0..<15 {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                if ScreenRecordingPermission.isGranted {
                    await MainActor.run {
                        self?.refreshPermissionState()
                        self?.statusMessage = "Permission granted — restart skap to apply"
                    }
                    return
                }
            }
        }
    }
}
