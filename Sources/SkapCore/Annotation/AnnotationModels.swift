import CoreGraphics
import Foundation

public enum AnnotationTool: String, CaseIterable, Sendable, Identifiable {
    case arrow
    case rectangle
    case ellipse
    case text
    case redact
    case highlight

    public var id: String { rawValue }
}

public enum RedactionStyle: String, CaseIterable, Sendable {
    case pixelate
    case gaussianBlur
}

public struct AnnotationElement: Identifiable, Sendable, Equatable {
    public var id: UUID
    public var tool: AnnotationTool
    public var frame: CGRect
    public var text: String?
    public var redactionStyle: RedactionStyle?

    public init(
        id: UUID = UUID(),
        tool: AnnotationTool,
        frame: CGRect,
        text: String? = nil,
        redactionStyle: RedactionStyle? = nil
    ) {
        self.id = id
        self.tool = tool
        self.frame = frame
        self.text = text
        self.redactionStyle = redactionStyle
    }
}
