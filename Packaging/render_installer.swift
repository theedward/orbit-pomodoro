import AppKit

let destination = URL(fileURLWithPath: CommandLine.arguments[1])
let iconURL = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
let ink = NSColor(srgbRed: 0.08, green: 0.16, blue: 0.20, alpha: 1)
let muted = NSColor(srgbRed: 0.37, green: 0.44, blue: 0.46, alpha: 1)
let mint = NSColor(srgbRed: 0.35, green: 0.65, blue: 0.60, alpha: 1)
func text(_ value: String, x: CGFloat, top: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = ink, tracking: CGFloat = 0) {
    NSAttributedString(string: value, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .kern: tracking]).draw(at: NSPoint(x: x, y: 480 - top - size * 1.2))
}
func background() {
    NSGradient(colors: [NSColor(srgbRed: 0.96, green: 0.98, blue: 0.97, alpha: 1), NSColor(srgbRed: 0.88, green: 0.94, blue: 0.93, alpha: 1)])!.draw(in: NSRect(x: 0, y: 0, width: 720, height: 480), angle: -30)
    // Faint orbital geometry gives the installer its own identity without
    // competing with Finder's actual draggable icons.
    NSGraphicsContext.saveGraphicsState()
    let clip = NSBezierPath(rect: NSRect(x: 420, y: 288, width: 300, height: 192)); clip.addClip()
    for i in 0..<3 {
        let orbit = NSBezierPath(ovalIn: NSRect(x: 460 - i * 24, y: 350 - i * 18, width: 310 + i * 48, height: 100 + i * 20))
        orbit.lineWidth = 1; mint.withAlphaComponent(0.14).setStroke(); orbit.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
    let mark = NSBezierPath(ovalIn: NSRect(x: 43, y: 418, width: 26, height: 26)); mark.lineWidth = 1.5; mint.setStroke(); mark.stroke()
    mint.setFill(); NSBezierPath(ovalIn: NSRect(x: 62, y: 438, width: 5, height: 5)).fill()
    text("O R B I T", x: 82, top: 38, size: 17, weight: .semibold)
    text("A TIMER FOR YOUR TIME", x: 501, top: 45, size: 8, weight: .medium, color: muted, tracking: 1.5)
    mint.withAlphaComponent(0.23).setFill(); NSRect(x: 42, y: 390, width: 636, height: 1).fill()
    text("Find your focus.", x: 42, top: 112, size: 35, weight: .medium, tracking: -1.1)
    text("One small step. A little more space to think.", x: 44, top: 160, size: 13, color: muted)
    for x: CGFloat in [120, 420] {
        let card = NSBezierPath(roundedRect: NSRect(x: x, y: 108, width: 180, height: 166), xRadius: 22, yRadius: 22)
        let shadow = NSShadow(); shadow.shadowColor = ink.withAlphaComponent(0.055); shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -3)
        NSGraphicsContext.saveGraphicsState(); shadow.set(); NSColor.white.withAlphaComponent(0.90).setFill(); card.fill(); NSGraphicsContext.restoreGraphicsState()
        mint.withAlphaComponent(0.17).setStroke(); card.lineWidth = 1; card.stroke()
    }
    let arrow = NSBezierPath(); arrow.move(to: NSPoint(x: 337, y: 198)); arrow.line(to: NSPoint(x: 383, y: 198))
    arrow.move(to: NSPoint(x: 372, y: 209)); arrow.line(to: NSPoint(x: 383, y: 198)); arrow.line(to: NSPoint(x: 372, y: 187))
    arrow.lineWidth = 2; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round; mint.setStroke(); arrow.stroke()
    text("Drag Orbit into Applications", x: 244, top: 395, size: 16, weight: .medium, tracking: -0.2)
    text("Then open Orbit from Applications to begin.", x: 229, top: 425, size: 12, color: muted)
    text("macOS 14+  /  Apple Silicon + Intel", x: 42, top: 457, size: 9, color: muted)
    text("YOUR TIME. YOUR ORBIT.", x: 547, top: 457, size: 8, weight: .medium, color: muted, tracking: 0.7)
}
func render(scale: Int, preview: Bool) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 720 * scale, pixelsHigh: 480 * scale, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 720, height: 480)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    background()
    if preview {
        NSImage(contentsOf: iconURL)!.draw(in: NSRect(x: 158, y: 150, width: 104, height: 104))
        NSImage(contentsOfFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ApplicationsFolderIcon.icns")!.draw(in: NSRect(x: 458, y: 150, width: 104, height: 104))
        text("Orbit", x: 195, top: 332, size: 13)
        text("Applications", x: 473, top: 332, size: 13)
    }
    NSGraphicsContext.restoreGraphicsState(); return rep
}
let image = NSImage(size: NSSize(width: 720, height: 480))
for scale in [1, 2] { image.addRepresentation(render(scale: scale, preview: false)) }
try image.tiffRepresentation!.write(to: destination.appendingPathComponent("background.tiff"))
try render(scale: 2, preview: true).representation(using: .png, properties: [:])!.write(to: destination.appendingPathComponent("installer-preview.png"))
