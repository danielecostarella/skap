#!/usr/bin/swift
// Generates the DMG installer background (660×400 px).
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let W = 660, H = 400
let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: W, height: H,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Flip to top-left origin
ctx.translateBy(x: 0, y: CGFloat(H))
ctx.scaleBy(x: 1, y: -1)

// ── Background ─────────────────────────────────────────────────────────────
ctx.setFillColor(CGColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

// Subtle inner shadow at top
let shadowGrad = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0, green: 0, blue: 0, alpha: 0.35),
        CGColor(red: 0, green: 0, blue: 0, alpha: 0)
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    shadowGrad,
    start: CGPoint(x: 0, y: 0),
    end:   CGPoint(x: 0, y: 60),
    options: []
)

// ── Divider line ───────────────────────────────────────────────────────────
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.07))
ctx.setLineWidth(1)
ctx.move(to: CGPoint(x: CGFloat(W)/2, y: 60))
ctx.addLine(to: CGPoint(x: CGFloat(W)/2, y: CGFloat(H) - 60))
ctx.strokePath()

// ── Arrow ─────────────────────────────────────────────────────────────────
let arrowY  = CGFloat(H) / 2 - 10
let arrowX1: CGFloat = 222
let arrowX2: CGFloat = 438
let blue = CGColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 0.85)

ctx.setStrokeColor(blue)
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)

// Shaft
ctx.move(to: CGPoint(x: arrowX1, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowX2, y: arrowY))
ctx.strokePath()

// Head
let headLen: CGFloat = 18
let headAngle: CGFloat = .pi / 5
ctx.move(to: CGPoint(x: arrowX2, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowX2 - headLen * Foundation.cos(-headAngle),
                         y: arrowY - headLen * Foundation.sin(-headAngle)))
ctx.move(to: CGPoint(x: arrowX2, y: arrowY))
ctx.addLine(to: CGPoint(x: arrowX2 - headLen * Foundation.cos(headAngle),
                         y: arrowY - headLen * Foundation.sin(headAngle)))
ctx.strokePath()

// ── Labels ────────────────────────────────────────────────────────────────
func drawCentered(_ text: String, cx: CGFloat, y: CGFloat, size: CGFloat, alpha: CGFloat = 1) {
    let font  = CTFontCreateWithName("Helvetica" as CFString, size, nil)
    let color = CGColor(red: 1, green: 1, blue: 1, alpha: alpha)
    let attrs = [kCTFontAttributeName: font,
                 kCTForegroundColorAttributeName: color] as CFDictionary
    let str  = CFAttributedStringCreate(nil, text as CFString, attrs)!
    let line = CTLineCreateWithAttributedString(str)
    let tw   = CTLineGetTypographicBounds(line, nil, nil, nil)
    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    ctx.textPosition = CGPoint(x: cx - tw / 2, y: y)
    CTLineDraw(line, ctx)
}

// Instruction text at top
drawCentered("Drag skap to Applications to install", cx: CGFloat(W)/2, y: 28, size: 12, alpha: 0.45)

// Column labels
let labelY = CGFloat(H) - 62
drawCentered("skap",          cx: 165, y: labelY, size: 11, alpha: 0.5)
drawCentered("Applications",  cx: 495, y: labelY, size: 11, alpha: 0.5)

// ── Save ──────────────────────────────────────────────────────────────────
guard let image = ctx.makeImage() else { exit(1) }
let out  = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png"
let url  = URL(fileURLWithPath: out)
let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { exit(1) }
