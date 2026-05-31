import AppKit
import CoreGraphics
import SkapCore
import SwiftUI

@MainActor
final class AreaSelectionController {
    private var panels: [NSPanel] = []

    func beginSelection(
        onSelected: @escaping @MainActor (CaptureArea) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        let screens = NSScreen.screens

        guard !screens.isEmpty else {
            onCancel()
            return
        }

        dismiss()

        for screen in screens {
            showSelectionPanel(
                on: screen,
                onSelected: onSelected,
                onCancel: onCancel
            )
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func showSelectionPanel(
        on screen: NSScreen,
        onSelected: @escaping @MainActor (CaptureArea) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
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
                    onSelected(CaptureArea(displayID: screen.displayID, pixelRect: pixelRect, scale: scale))
                },
                onCancel: { [weak self] in
                    self?.dismiss()
                    onCancel()
                }
            )
        )

        panels.append(selectionPanel)
        selectionPanel.makeKeyAndOrderFront(nil)
    }

    private func dismiss() {
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
    }
}
