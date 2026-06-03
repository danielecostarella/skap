import CoreGraphics
import Testing
@testable import SkapCore

@Test func annotationRendererReturnsImageForEmptyElements() throws {
    let image = try rendererTestImage(width: 20, height: 20)
    let rendered = AnnotationRenderer().render(
        elements: [],
        onto: image,
        viewSize: CGSize(width: 20, height: 20)
    )

    #expect(rendered?.width == 20)
    #expect(rendered?.height == 20)
}

@Test func annotationRendererRendersEveryTool() throws {
    let image = try rendererTestImage(width: 120, height: 90)
    let elements: [AnnotationElement] = [
        AnnotationElement(tool: .arrow, frame: CGRect(x: 10, y: 10, width: 40, height: 20), color: .red),
        AnnotationElement(tool: .rectangle, frame: CGRect(x: 20, y: 20, width: 40, height: 30), color: .blue),
        AnnotationElement(tool: .ellipse, frame: CGRect(x: 30, y: 15, width: 30, height: 25), color: .green),
        AnnotationElement(tool: .highlight, frame: CGRect(x: 5, y: 50, width: 50, height: 20), color: .yellow),
        AnnotationElement(tool: .pen, frame: CGRect(x: 70, y: 10, width: 30, height: 30), color: .orange, points: [
            CGPoint(x: 70, y: 10),
            CGPoint(x: 90, y: 25),
            CGPoint(x: 100, y: 40),
        ]),
        AnnotationElement(tool: .text, frame: CGRect(x: 10, y: 70, width: 0, height: 0), text: "Hi", color: .white),
        AnnotationElement(tool: .redact, frame: CGRect(x: 75, y: 45, width: 30, height: 20), redactionStyle: .pixelate),
    ]

    let rendered = AnnotationRenderer().render(
        elements: elements,
        onto: image,
        viewSize: CGSize(width: 120, height: 90)
    )

    #expect(rendered?.width == 120)
    #expect(rendered?.height == 90)
}

private func rendererTestImage(width: Int, height: Int) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw RendererTestImageError.cannotCreateContext
    }

    context.setFillColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let image = context.makeImage() else {
        throw RendererTestImageError.cannotCreateImage
    }
    return image
}

private enum RendererTestImageError: Error {
    case cannotCreateContext
    case cannotCreateImage
}
