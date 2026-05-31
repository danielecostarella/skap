import AppKit
import SkapCore
import SwiftUI

@MainActor
final class PinWindowController {
    private var windows: [NSWindow] = []

    func pin(image: CapturedImage) {
        let view = PinnedImageView(image: image)
        let hostingController = NSHostingController(rootView: view)
        let window = NSPanel(
            contentRect: NSRect(x: 160, y: 160, width: 480, height: 300),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Pinned Screenshot"
        window.contentViewController = hostingController
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.makeKeyAndOrderFront(nil)

        windows.append(window)
    }
}
