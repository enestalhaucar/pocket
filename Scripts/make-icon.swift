#!/usr/bin/env swift
// Renders pocket's app icon (gradient squircle + tray glyph) into an .icns.
// Usage: swift Scripts/make-icon.swift <output.icns>
import Cocoa

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.icns"

let c1 = NSColor(calibratedRed: 0.36, green: 0.36, blue: 0.96, alpha: 1)
let c2 = NSColor(calibratedRed: 0.55, green: 0.36, blue: 0.96, alpha: 1)

func renderPNG(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(px)
    // Slight inset so the squircle doesn't touch the edges (macOS icon grid).
    let inset = size * 0.08
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.235

    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSGradient(colors: [c1, c2])!.draw(in: rect, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    if let sym = NSImage(systemSymbolName: "tray.full.fill", accessibilityDescription: nil) {
        let conf = NSImage.SymbolConfiguration(pointSize: rect.width * 0.5, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        let glyph = sym.withSymbolConfiguration(conf) ?? sym
        let gs = glyph.size
        let gr = NSRect(x: rect.midX - gs.width / 2, y: rect.midY - gs.height / 2,
                        width: gs.width, height: gs.height)
        glyph.draw(in: gr)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// Build a .iconset directory, then convert with iconutil.
let fm = FileManager.default
let tmp = NSTemporaryDirectory() + "pocket-\(getpid()).iconset"
try? fm.removeItem(atPath: tmp)
try! fm.createDirectory(atPath: tmp, withIntermediateDirectories: true)

let specs: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
var cache: [Int: Data] = [:]
for (px, name) in specs {
    let data = cache[px] ?? renderPNG(px)
    cache[px] = data
    try! data.write(to: URL(fileURLWithPath: tmp + "/" + name))
}

let out = URL(fileURLWithPath: outPath)
try? fm.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)

let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", tmp, "-o", outPath]
try! p.run()
p.waitUntilExit()
try? fm.removeItem(atPath: tmp)

print(p.terminationStatus == 0 ? "✓ wrote \(outPath)" : "✗ iconutil failed")
exit(p.terminationStatus)
