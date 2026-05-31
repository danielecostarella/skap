import AppKit
import CoreGraphics
import Darwin

@MainActor
final class WindowSelectionController {
    private var panels: [NSPanel] = []

    func beginSelection(
        onSelected: @escaping @MainActor (CGWindowID) -> Void,
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
        onSelected: @escaping @MainActor (CGWindowID) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        let selectionPanel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let pickerView = WindowSelectionView(
            frame: NSRect(origin: .zero, size: screen.frame.size),
            screen: screen,
            onSelected: { [weak self] windowID in
                self?.dismiss()
                onSelected(windowID)
            },
            onCancel: { [weak self] in
                self?.dismiss()
                onCancel()
            }
        )

        selectionPanel.level = .screenSaver
        selectionPanel.backgroundColor = .clear
        selectionPanel.isOpaque = false
        selectionPanel.hasShadow = false
        selectionPanel.ignoresMouseEvents = false
        selectionPanel.acceptsMouseMovedEvents = true
        selectionPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        selectionPanel.contentView = pickerView

        panels.append(selectionPanel)
        selectionPanel.makeKeyAndOrderFront(nil)
        selectionPanel.makeFirstResponder(pickerView)
    }

    private func dismiss() {
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
    }
}

private final class WindowSelectionView: NSView {
    private let targetScreen: NSScreen
    private let onSelected: @MainActor (CGWindowID) -> Void
    private let onCancel: @MainActor () -> Void
    private var highlightedWindow: WindowCandidate?
    private var trackingAreaToken: NSTrackingArea?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    init(
        frame: NSRect,
        screen: NSScreen,
        onSelected: @escaping @MainActor (CGWindowID) -> Void,
        onCancel: @escaping @MainActor () -> Void
    ) {
        self.targetScreen = screen
        self.onSelected = onSelected
        self.onCancel = onCancel
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.18).cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingAreaToken {
            removeTrackingArea(trackingAreaToken)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaToken = trackingArea
    }

    override func mouseMoved(with event: NSEvent) {
        highlightedWindow = windowCandidate(at: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        highlightedWindow = windowCandidate(at: convert(event.locationInWindow, from: nil))

        guard let highlightedWindow else {
            onCancel()
            return
        }

        onSelected(highlightedWindow.id)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let highlightedWindow else {
            return
        }

        NSColor.black.withAlphaComponent(0.18).setFill()
        dirtyRect.fill()

        NSColor.clear.setFill()
        highlightedWindow.rect.fill(using: .copy)

        NSColor.white.withAlphaComponent(0.95).setStroke()
        let path = NSBezierPath(roundedRect: highlightedWindow.rect, xRadius: 8, yRadius: 8)
        path.lineWidth = 2
        path.stroke()
    }

    private func windowCandidate(at point: CGPoint) -> WindowCandidate? {
        windowCandidates().first { $0.rect.contains(point) }
    }

    private func windowCandidates() -> [WindowCandidate] {
        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return windowInfo.compactMap { info in
            guard
                let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0,
                let alpha = info[kCGWindowAlpha as String] as? Double,
                alpha > 0,
                let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                ownerPID != getpid(),
                let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
                let quartzRect = CGRect(dictionaryRepresentation: boundsDictionary)
            else {
                return nil
            }

            let localRect = targetScreen.localWindowRect(fromGlobalWindowRect: quartzRect)

            guard localRect.width >= 24, localRect.height >= 24 else {
                return nil
            }

            guard bounds.intersects(localRect) else {
                return nil
            }

            return WindowCandidate(id: windowID, rect: localRect)
        }
    }
}

private struct WindowCandidate {
    let id: CGWindowID
    let rect: CGRect
}

private extension NSScreen {
    func localWindowRect(fromGlobalWindowRect rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - frame.minX,
            y: rect.minY - frame.minY,
            width: rect.width,
            height: rect.height
        )
    }
}
