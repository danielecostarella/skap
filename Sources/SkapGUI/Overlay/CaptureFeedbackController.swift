import AppKit
import SkapCore
import SwiftUI

@MainActor
final class CaptureFeedbackController {
    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    func show(image: CapturedImage, message: String) {
        let view = CaptureFeedbackView(image: image, message: message, isError: false)
        present(view: view, duration: 1.4)
    }

    func showError(message: String) {
        let view = CaptureFeedbackView(image: nil, message: message, isError: true)
        present(view: view, duration: 3.0)
    }

    private func present(view: some View, duration: Double) {
        dismissTask?.cancel()

        guard let screen = NSScreen.main else { return }

        let size = NSSize(width: 260, height: 88)
        let margin: CGFloat = 24
        let frame = NSRect(
            x: screen.visibleFrame.maxX - size.width - margin,
            y: screen.visibleFrame.minY + margin,
            width: size.width,
            height: size.height
        )

        let feedbackPanel = panel ?? NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        feedbackPanel.setFrame(frame, display: true)
        feedbackPanel.level = .floating
        feedbackPanel.backgroundColor = .clear
        feedbackPanel.isOpaque = false
        feedbackPanel.hasShadow = false
        feedbackPanel.ignoresMouseEvents = true
        feedbackPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        feedbackPanel.contentView = NSHostingView(rootView: AnyView(view))

        panel = feedbackPanel
        feedbackPanel.orderFrontRegardless()

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.dismiss()
        }
    }

    private func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        dismissTask = nil
    }
}
