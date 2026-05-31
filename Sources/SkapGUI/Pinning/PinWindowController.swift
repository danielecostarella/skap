import AppKit
import SkapCore
import SwiftUI

@MainActor
final class PinWindowController {
    private var windows: [NSWindow] = []

    func pin(image: CapturedImage) {
        let windowSize = NSSize(width: 520, height: 340)
        let windowOrigin = NSScreen.main.map { screen in
            NSPoint(
                x: screen.visibleFrame.midX - windowSize.width / 2,
                y: screen.visibleFrame.midY - windowSize.height / 2
            )
        } ?? NSPoint(x: 160, y: 160)
        let view = PinnedImageView(image: image)
        let hostingController = NSHostingController(rootView: view)
        let window = NSPanel(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Pinned Screenshot - Always on Top"
        window.contentViewController = hostingController
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.center()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        windows.append(window)
    }
}
