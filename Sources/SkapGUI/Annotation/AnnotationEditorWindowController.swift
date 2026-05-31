import AppKit
import SkapCore
import SwiftUI

@MainActor
final class AnnotationEditorWindowController: NSWindowController {
    var onDone: ((CGImage) -> Void)?

    private let capturedImage: CapturedImage

    init(capturedImage: CapturedImage) {
        self.capturedImage = capturedImage

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Edit Screenshot"
        window.minSize = NSSize(width: 480, height: 360)
        window.center()
        super.init(window: window)
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupContent() {
        let view = AnnotationEditorView(
            baseImage: capturedImage.cgImage,
            onDone: { [weak self] renderedImage in
                self?.onDone?(renderedImage)
                self?.close()
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )
        window?.contentView = NSHostingView(rootView: view)
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
