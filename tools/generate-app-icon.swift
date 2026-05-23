#!/usr/bin/env swift

import AppKit
import Foundation

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let buildURL = rootURL.appendingPathComponent("build", isDirectory: true)
let resourcesURL = rootURL.appendingPathComponent("App/Resources", isDirectory: true)
let iconsetURL = buildURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let outputURL = resourcesURL.appendingPathComponent("AppIcon.icns")

let iconFiles: [(name: String, pixels: CGFloat)] = [
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

try fileManager.createDirectory(at: buildURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for iconFile in iconFiles {
    let image = drawIcon(size: iconFile.pixels)
    try writePNG(image, to: iconsetURL.appendingPathComponent(iconFile.name))
}

try runIconutil(iconsetURL: iconsetURL, outputURL: outputURL)
try? fileManager.removeItem(at: iconsetURL)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high
    drawBackground(size: size)
    drawSecondaryDisplay(size: size)
    drawPrimaryDisplay(size: size)
    drawStand(size: size)
    drawAccent(size: size)

    return image
}

func drawBackground(size: CGFloat) {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1).setFill()
    path.fill()
}

func drawSecondaryDisplay(size: CGFloat) {
    let rect = NSRect(x: size * 0.15, y: size * 0.43, width: size * 0.46, height: size * 0.27)
    drawDisplay(rect: rect, radius: size * 0.035, fill: NSColor(calibratedRed: 0.12, green: 0.33, blue: 0.39, alpha: 1))
}

func drawPrimaryDisplay(size: CGFloat) {
    let rect = NSRect(x: size * 0.24, y: size * 0.31, width: size * 0.58, height: size * 0.36)
    drawDisplay(rect: rect, radius: size * 0.04, fill: NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.22, alpha: 1))
}

func drawDisplay(rect: NSRect, radius: CGFloat, fill: NSColor) {
    let outer = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor(calibratedWhite: 0.94, alpha: 1).setFill()
    outer.fill()

    let inner = rect.insetBy(dx: rect.width * 0.055, dy: rect.height * 0.075)
    let innerPath = NSBezierPath(roundedRect: inner, xRadius: radius * 0.65, yRadius: radius * 0.65)
    fill.setFill()
    innerPath.fill()
}

func drawStand(size: CGFloat) {
    let stem = NSBezierPath(roundedRect: NSRect(
        x: size * 0.47,
        y: size * 0.23,
        width: size * 0.12,
        height: size * 0.095
    ), xRadius: size * 0.018, yRadius: size * 0.018)
    NSColor(calibratedWhite: 0.88, alpha: 1).setFill()
    stem.fill()

    let base = NSBezierPath(roundedRect: NSRect(
        x: size * 0.37,
        y: size * 0.19,
        width: size * 0.32,
        height: size * 0.055
    ), xRadius: size * 0.025, yRadius: size * 0.025)
    NSColor(calibratedWhite: 0.88, alpha: 1).setFill()
    base.fill()
}

func drawAccent(size: CGFloat) {
    let path = NSBezierPath(roundedRect: NSRect(
        x: size * 0.33,
        y: size * 0.53,
        width: size * 0.34,
        height: size * 0.055
    ), xRadius: size * 0.027, yRadius: size * 0.027)
    NSColor(calibratedRed: 0.36, green: 0.77, blue: 0.63, alpha: 1).setFill()
    path.fill()
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render PNG."])
    }

    try pngData.write(to: url)
}

func runIconutil(iconsetURL: URL, outputURL: URL) throws {
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
        throw NSError(
            domain: "AppIcon",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "iconutil failed."]
        )
    }
}
