// Renders the DMG window background: an arrow from the app icon to the
// Applications shortcut, with a one-line hint. Usage:
//   swift Tools/MakeDMGBackground.swift <output.png>
// Geometry matches the Finder layout in make-dmg.sh: a 540×340 pt window,
// icons centred at x 140 and x 400, y 160 (Finder's y runs top-down).

import AppKit

let size = NSSize(width: 540, height: 340)
let scale: CGFloat = 2   // Retina: 1080×680 px at 144 dpi

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: MakeDMGBackground.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = size   // point size, so Finder draws it at 144 dpi

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Light neutral background: Finder draws icon labels in dark text on it.
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

// Arrow between the icons (AppKit's y runs bottom-up: Finder y 160 → 180).
let arrowY: CGFloat = size.height - 160
let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 225, y: arrowY))
arrow.line(to: NSPoint(x: 305, y: arrowY))
arrow.move(to: NSPoint(x: 290, y: arrowY + 12))
arrow.line(to: NSPoint(x: 307, y: arrowY))
arrow.line(to: NSPoint(x: 290, y: arrowY - 12))
arrow.lineWidth = 5
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
NSColor(calibratedWhite: 0.55, alpha: 1).setStroke()
arrow.stroke()

// Hint along the bottom.
let hint = "Drag Slateflow to Applications to install" as NSString
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.4, alpha: 1),
]
let hintSize = hint.size(withAttributes: attributes)
hint.draw(at: NSPoint(x: (size.width - hintSize.width) / 2, y: 36), withAttributes: attributes)

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
