import AppKit
import CoreGraphics

public protocol ClipboardWriting: Sendable {
    @MainActor
    func write(_ image: CGImage)
}

public struct PasteboardClipboardWriter: ClipboardWriting {
    public init() {}

    @MainActor
    public func write(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: image, size: .zero)])
    }
}
