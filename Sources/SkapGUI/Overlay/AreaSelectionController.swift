import AppKit
import CoreGraphics
import SkapCore
import SwiftUI

@MainActor
final class AreaSelectionController {
    private var panel: NSPanel?

    func beginSelection(
        onSelected: @escaping @MainActor (CaptureArea) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        guard let screen = NSScreen.main else {
            onCancel()
            return
        }

        let selectionPanel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        selectionPanel.level = .screenSaver
        selectionPanel.backgroundColor = .clear
        selectionPanel.isOpaque = false
        selectionPanel.hasShadow = false
        selectionPanel.ignoresMouseEvents = false
        selectionPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        selectionPanel.contentView = NSHostingView(
            rootView: AreaSelectionView(
                onSelected: { [weak self, weak screen] rect in
                    self?.dismiss()

                    guard
                        let screen,
                        rect.width >= 4,
                        rect.height >= 4
                    else {
                        onCancel()
                        return
                    }

                    let scale = screen.backingScaleFactor
                    let pixelRect = CGRect(
                        x: rect.minX * scale,
                        y: rect.minY * scale,
                        width: rect.width * scale,
                        height: rect.height * scale
                    )
                    onSelected(CaptureArea(displayID: screen.displayID, pixelRect: pixelRect))
                },
                onCancel: { [weak self] in
                    self?.dismiss()
                    onCancel()
                }
            )
        )

        panel = selectionPanel
        selectionPanel.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
    }
}
