import CoreGraphics
import CoreImage
import CoreText
import Foundation

public struct AnnotationRenderer: Sendable {
    public init() {}

    /// Renders annotation elements onto a CGImage.
    /// - Parameters:
    ///   - elements: Annotations to draw. Frames are in view coordinates.
    ///   - image: The base image to annotate.
    ///   - viewSize: The size of the canvas where annotations were drawn.
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

        // CGContext origin is bottom-left; flip to top-left for consistency with SwiftUI canvas
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let scaleX = CGFloat(width) / viewSize.width
        let scaleY = CGFloat(height) / viewSize.height

        for element in elements {
            let scaled = scale(element, scaleX: scaleX, scaleY: scaleY)
            render(element: scaled, onto: image, in: context, imageSize: CGSize(width: width, height: height))
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
        return AnnotationElement(id: element.id, tool: element.tool, frame: scaled, text: element.text, redactionStyle: element.redactionStyle)
    }

    private func render(element: AnnotationElement, onto baseImage: CGImage, in context: CGContext, imageSize: CGSize) {
        context.saveGState()
        defer { context.restoreGState() }

        switch element.tool {
        case .arrow:
            let start = element.frame.origin
            let end = CGPoint(x: start.x + element.frame.size.width, y: start.y + element.frame.size.height)
            drawArrow(from: start, to: end, in: context)

        case .rectangle:
            context.setStrokeColor(annotationColor)
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.stroke(element.frame.standardized)

        case .ellipse:
            context.setStrokeColor(annotationColor)
            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: element.frame.standardized)

        case .highlight:
            context.setFillColor(highlightColor)
            context.fill(element.frame.standardized)

        case .text:
            if let text = element.text, !text.isEmpty {
                drawText(text, at: element.frame.origin, in: context)
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

    private func drawArrow(from start: CGPoint, to end: CGPoint, in context: CGContext) {
        context.setStrokeColor(annotationColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)

        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = max(lineWidth * 5, 16)
        let headAngle: CGFloat = .pi / 6

        let p1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        let p2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )

        context.move(to: end)
        context.addLine(to: p1)
        context.move(to: end)
        context.addLine(to: p2)
        context.strokePath()
    }

    private func drawText(_ text: String, at origin: CGPoint, in context: CGContext) {
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 18, nil)
        let color = CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
        let attrs = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: color] as CFDictionary
        let attrString = CFAttributedStringCreate(nil, text as CFString, attrs)!
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = origin
        CTLineDraw(line, context)
    }

    private func drawRedaction(in frame: CGRect, style: RedactionStyle, baseImage: CGImage, in context: CGContext, imageSize: CGSize) {
        // Crop the base image region and apply blur/pixelate
        // CIImage origin is bottom-left, so flip the y coordinate
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

    private var annotationColor: CGColor {
        CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 1) // red
    }

    private var highlightColor: CGColor {
        CGColor(red: 1, green: 0.95, blue: 0, alpha: 0.4) // semi-transparent yellow
    }

    private var lineWidth: CGFloat { 3 }
}
