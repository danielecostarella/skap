#!/usr/bin/env swift

import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = rootURL
    .appendingPathComponent("Packaging")
    .appendingPathComponent("Skap.app")
    .appendingPathComponent("Contents")
    .appendingPathComponent("Resources")
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset")
let outputURL = resourcesURL.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let renditions: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for rendition in renditions {
    let image = drawIcon(size: CGFloat(rendition.pixels))
    let fileURL = iconsetURL.appendingPathComponent(rendition.name)
    try writePNG(image, to: fileURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c",
    "icns",
    iconsetURL.path,
    "-o",
    outputURL.path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw IconGenerationError.iconutilFailed(process.terminationStatus)
}

try? FileManager.default.removeItem(at: iconsetURL)
print("Created \(outputURL.path)")

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let background = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.06, dy: size * 0.06), xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(colors: [
        NSColor(red: 0.08, green: 0.10, blue: 0.13, alpha: 1.0),
        NSColor(red: 0.02, green: 0.42, blue: 0.48, alpha: 1.0)
    ])?.draw(in: background, angle: 35)

    NSColor.white.withAlphaComponent(0.12).setStroke()
    background.lineWidth = max(1, size * 0.012)
    background.stroke()

    let cropRect = NSRect(
        x: size * 0.25,
        y: size * 0.27,
        width: size * 0.50,
        height: size * 0.46
    )
    let cropPath = NSBezierPath(roundedRect: cropRect, xRadius: size * 0.055, yRadius: size * 0.055)
    NSColor.white.withAlphaComponent(0.94).setStroke()
    cropPath.lineWidth = max(2, size * 0.045)
    cropPath.stroke()

    NSColor(red: 0.60, green: 0.95, blue: 0.85, alpha: 1.0).setFill()
    for point in [
        NSPoint(x: cropRect.minX, y: cropRect.minY),
        NSPoint(x: cropRect.maxX, y: cropRect.minY),
        NSPoint(x: cropRect.minX, y: cropRect.maxY),
        NSPoint(x: cropRect.maxX, y: cropRect.maxY)
    ] {
        NSBezierPath(ovalIn: NSRect(
            x: point.x - size * 0.035,
            y: point.y - size * 0.035,
            width: size * 0.07,
            height: size * 0.07
        )).fill()
    }

    let repeatPath = NSBezierPath()
    repeatPath.move(to: NSPoint(x: size * 0.34, y: size * 0.80))
    repeatPath.curve(
        to: NSPoint(x: size * 0.66, y: size * 0.80),
        controlPoint1: NSPoint(x: size * 0.42, y: size * 0.91),
        controlPoint2: NSPoint(x: size * 0.58, y: size * 0.91)
    )
    NSColor(red: 0.60, green: 0.95, blue: 0.85, alpha: 1.0).setStroke()
    repeatPath.lineWidth = max(2, size * 0.035)
    repeatPath.lineCapStyle = .round
    repeatPath.stroke()

    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: size * 0.65, y: size * 0.80))
    arrow.line(to: NSPoint(x: size * 0.59, y: size * 0.87))
    arrow.move(to: NSPoint(x: size * 0.65, y: size * 0.80))
    arrow.line(to: NSPoint(x: size * 0.57, y: size * 0.77))
    arrow.lineWidth = max(2, size * 0.035)
    arrow.lineCapStyle = .round
    arrow.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw IconGenerationError.pngEncodingFailed
    }

    try pngData.write(to: url, options: .atomic)
}

enum IconGenerationError: Error {
    case pngEncodingFailed
    case iconutilFailed(Int32)
}
