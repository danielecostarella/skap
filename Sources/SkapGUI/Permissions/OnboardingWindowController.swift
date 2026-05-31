import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to skap"
        window.isMovableByWindowBackground = true
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func showIfNeeded() {
        guard !ScreenRecordingPermission.isGranted else { return }
        show()
    }

    func show() {
        let view = OnboardingView(onDismiss: { [weak self] in
            self?.close()
        })
        window?.contentView = NSHostingView(rootView: view)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
