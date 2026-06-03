import CoreGraphics
import CoreImage
import CoreText
import Foundation

public struct AnnotationRenderer: Sendable {
    public init() {}

    public func render(elements: [AnnotationElement], onto image: CGImage, viewSize: CGSize) -> CGImage? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Draw base image BEFORE flipping — in natural CG coordinates (y=0 at bottom)
        // context.draw maps image upright in the standard bottom-left system.
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Flip to top-left origin so annotation frames from SwiftUI canvas map directly.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        let scaleX = CGFloat(width) / viewSize.width
        let scaleY = CGFloat(height) / viewSize.height

        for element in elements {
            let scaled = scale(element, scaleX: scaleX, scaleY: scaleY)
            let metrics = AnnotationMetrics(scale: max((scaleX + scaleY) / 2, 1))
            render(element: scaled, onto: image, in: context, imageSize: CGSize(width: width, height: height), metrics: metrics)
        }

        return context.makeImage()
    }

    private func scale(_ element: AnnotationElement, scaleX: CGFloat, scaleY: CGFloat) -> AnnotationElement {
        let f = element.frame
        let scaled = CGRect(
            x: f.origin.x * scaleX,
            y: f.origin.y * scaleY,
            width: f.size.width * scaleX,
            height: f.size.height * scaleY
        )
        let scaledPoints = element.points?.map {
            CGPoint(x: $0.x * scaleX, y: $0.y * scaleY)
        }
        return AnnotationElement(
            id: element.id, tool: element.tool, frame: scaled,
            text: element.text, redactionStyle: element.redactionStyle,
            color: element.color, points: scaledPoints
        )
    }

    private func render(
        element: AnnotationElement,
        onto baseImage: CGImage,
        in context: CGContext,
        imageSize: CGSize,
        metrics: AnnotationMetrics
    ) {
        context.saveGState()
        defer { context.restoreGState() }

        switch element.tool {
        case .arrow:
            let start = element.frame.origin
            let end = CGPoint(x: start.x + element.frame.size.width, y: start.y + element.frame.size.height)
            drawArrow(from: start, to: end, color: element.color, in: context, metrics: metrics)

        case .rectangle:
            context.setStrokeColor(element.color.cgColor)
            context.setLineWidth(metrics.lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.stroke(element.frame.standardized)

        case .ellipse:
            context.setStrokeColor(element.color.cgColor)
            context.setLineWidth(metrics.lineWidth)
            context.strokeEllipse(in: element.frame.standardized)

        case .highlight:
            context.setFillColor(element.color.highlightCGColor())
            context.fill(element.frame.standardized)

        case .pen:
            if let pts = element.points, pts.count > 1 {
                drawPen(pts, color: element.color, in: context, metrics: metrics)
            }

        case .text:
            if let text = element.text, !text.isEmpty {
                drawText(text, at: element.frame.origin, color: element.color, in: context, metrics: metrics)
            }

        case .redact:
            drawRedaction(
                in: element.frame.standardized,
                style: element.redactionStyle ?? .pixelate,
                baseImage: baseImage,
                in: context,
                imageSize: imageSize
            )
        }
    }

    private func drawArrow(from start: CGPoint, to end: CGPoint, color: AnnotationColor, in context: CGContext, metrics: AnnotationMetrics) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(metrics.lineWidth)
        context.setLineCap(.round)

        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = max(metrics.lineWidth * 5, 16 * metrics.scale)
        let headAngle: CGFloat = .pi / 6

        context.move(to: end)
        context.addLine(to: CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        ))
        context.move(to: end)
        context.addLine(to: CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        ))
        context.strokePath()
    }

    private func drawPen(_ points: [CGPoint], color: AnnotationColor, in context: CGContext, metrics: AnnotationMetrics) {
        context.setStrokeColor(color.highlightCGColor())
        context.setLineWidth(metrics.highlightWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: points[0])
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()
    }

    private func drawText(_ text: String, at origin: CGPoint, color: AnnotationColor, in context: CGContext, metrics: AnnotationMetrics) {
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, metrics.fontSize, nil)
        let attrs = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: color.cgColor] as CFDictionary
        let attrString = CFAttributedStringCreate(nil, text as CFString, attrs)!
        let line = CTLineCreateWithAttributedString(attrString)
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        context.textPosition = origin
        CTLineDraw(line, context)
    }

    private func drawRedaction(in frame: CGRect, style: RedactionStyle, baseImage: CGImage, in context: CGContext, imageSize: CGSize) {
        let ciFrame = CGRect(
            x: frame.minX,
            y: imageSize.height - frame.maxY,
            width: frame.width,
            height: frame.height
        )
        guard ciFrame.width > 0, ciFrame.height > 0 else { return }

        let ciImage = CIImage(cgImage: baseImage).cropped(to: ciFrame)
        let filterName = style == .pixelate ? "CIPixellate" : "CIGaussianBlur"
        guard let filter = CIFilter(name: filterName) else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        switch style {
        case .pixelate:
            filter.setValue(max(frame.width, frame.height) / 12, forKey: kCIInputScaleKey)
        case .gaussianBlur:
            filter.setValue(15.0, forKey: kCIInputRadiusKey)
        }

        guard let output = filter.outputImage else { return }
        let ciContext = CIContext()
        guard let blurred = ciContext.createCGImage(output, from: ciFrame) else { return }
        context.draw(blurred, in: frame)
    }

    private struct AnnotationMetrics {
        var scale: CGFloat
        var lineWidth: CGFloat { 3 * scale }
        var highlightWidth: CGFloat { 18 * scale }
        var fontSize: CGFloat { 18 * scale }
    }
}
