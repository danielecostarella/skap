import AppKit
import Carbon
import SkapCore
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var config: ShortcutConfig

    func makeCoordinator() -> Coordinator {
        Coordinator(config: $config)
    }

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.config = config
        button.onConfigChange = { [coordinator = context.coordinator] newConfig in
            coordinator.config.wrappedValue = newConfig
        }
        return button
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.config = config
        nsView.needsDisplay = true
    }

    final class Coordinator {
        var config: Binding<ShortcutConfig>
        init(config: Binding<ShortcutConfig>) { self.config = config }
    }
}

final class ShortcutRecorderButton: NSView {
    var config: ShortcutConfig = ShortcutConfig(keyCode: 18, modifiers: 768) {
        didSet { needsDisplay = true }
    }
    var onConfigChange: ((ShortcutConfig) -> Void)?

    private var isRecording = false
    private var localMonitor: Any?

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 140, height: 22) }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        let radius: CGFloat = 4

        let bgColor: NSColor = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.15)
            : NSColor.controlBackgroundColor

        bgColor.setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius)
        path.fill()

        let borderColor: NSColor = isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor
        borderColor.setStroke()
        path.lineWidth = 1
        path.stroke()

        let text = isRecording ? "Type shortcut…" : ShortcutFormatter.format(config)
        let color: NSColor = isRecording ? .placeholderTextColor : .labelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: color
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let textSize = attributed.size()
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributed.draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        startRecording()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 { // Escape
            stopRecording(save: false)
            return
        }

        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return }

        let newConfig = ShortcutConfig(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        stopRecording(save: false)
        onConfigChange?(newConfig)
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { stopRecording(save: false) }
        return super.resignFirstResponder()
    }

    private func startRecording() {
        isRecording = true
        needsDisplay = true
    }

    private func stopRecording(save: Bool) {
        isRecording = false
        needsDisplay = true
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}

enum ShortcutFormatter {
    static func format(_ config: ShortcutConfig) -> String {
        var result = ""
        if config.modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if config.modifiers & UInt32(optionKey)  != 0 { result += "⌥" }
        if config.modifiers & UInt32(shiftKey)   != 0 { result += "⇧" }
        if config.modifiers & UInt32(cmdKey)     != 0 { result += "⌘" }
        result += keyName(for: config.keyCode)
        return result
    }

    private static func keyName(for keyCode: UInt32) -> String {
        // Virtual key code → display name (US ANSI layout)
        let table: [UInt32: String] = [
            0: "A",  1: "S",  2: "D",  3: "F",  4: "H",  5: "G",
            6: "Z",  7: "X",  8: "C",  9: "V", 11: "B", 12: "Q",
            13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1",
            19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
            25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
            31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 50: "`",
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            117: "⌦", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1",  120: "F2",  99: "F3",  118: "F4",
            96: "F5",   97: "F6",  98: "F7",  100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12",
        ]
        return table[keyCode] ?? "?"
    }
}
