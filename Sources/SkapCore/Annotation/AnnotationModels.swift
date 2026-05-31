import CoreGraphics
import Foundation

public enum AnnotationTool: String, CaseIterable, Sendable, Identifiable {
    case arrow
    case rectangle
    case ellipse
    case text
    case pen
    case highlight
    case redact

    public var id: String { rawValue }
}

public enum RedactionStyle: String, CaseIterable, Sendable {
    case pixelate
    case gaussianBlur
}

public enum AnnotationColor: String, CaseIterable, Sendable {
    case red, orange, yellow, green, blue, white

    public var cgColor: CGColor {
        switch self {
        case .red:    CGColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1)
        case .orange: CGColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1)
        case .yellow: CGColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 1)
        case .green:  CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        case .blue:   CGColor(red: 0.04, green: 0.52, blue: 1.00, alpha: 1)
        case .white:  CGColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)
        }
    }

    public func highlightCGColor() -> CGColor {
        switch self {
        case .red:    CGColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 0.35)
        case .orange: CGColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 0.35)
        case .yellow: CGColor(red: 1.00, green: 0.80, blue: 0.00, alpha: 0.40)
        case .green:  CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 0.35)
        case .blue:   CGColor(red: 0.04, green: 0.52, blue: 1.00, alpha: 0.35)
        case .white:  CGColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.35)
        }
    }
}

public struct AnnotationElement: Identifiable, Sendable, Equatable {
    public var id: UUID
    public var tool: AnnotationTool
    public var frame: CGRect
    public var text: String?
    public var redactionStyle: RedactionStyle?
    public var color: AnnotationColor
    public var points: [CGPoint]?

    public init(
        id: UUID = UUID(),
        tool: AnnotationTool,
        frame: CGRect,
        text: String? = nil,
        redactionStyle: RedactionStyle? = nil,
        color: AnnotationColor = .red,
        points: [CGPoint]? = nil
    ) {
        self.id = id
        self.tool = tool
        self.frame = frame
        self.text = text
        self.redactionStyle = redactionStyle
        self.color = color
        self.points = points
    }
}
