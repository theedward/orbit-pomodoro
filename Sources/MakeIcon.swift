// Run separately with Swift; excluded from the app's compile command.
import AppKit
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let shape = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960), xRadius: 220, yRadius: 220)
NSGradient(colors: [NSColor(red: 0.12, green: 0.26, blue: 0.34, alpha: 1), NSColor(red: 0.025, green: 0.05, blue: 0.10, alpha: 1)])!.draw(in: shape, angle: -65)
let mint = NSColor(red: 0.67, green: 0.96, blue: 0.86, alpha: 1)
mint.withAlphaComponent(0.2).setStroke()
let orbit = NSBezierPath(ovalIn: NSRect(x: 130, y: 370, width: 764, height: 284))
let transform = AffineTransform(translationByX: -512, byY: -512)
orbit.transform(using: transform)
var rotation = AffineTransform(); rotation.rotate(byDegrees: 32); orbit.transform(using: rotation)
orbit.transform(using: AffineTransform(translationByX: 512, byY: 512))
orbit.lineWidth = 4; orbit.stroke()
let dial = NSBezierPath(); dial.appendArc(withCenter: NSPoint(x: 512, y: 512), radius: 280, startAngle: 95, endAngle: 440, clockwise: false)
mint.setStroke(); dial.lineWidth = 17; dial.lineCapStyle = .round; dial.stroke()
mint.setFill(); NSBezierPath(ovalIn: NSRect(x: 529, y: 760, width: 48, height: 48)).fill()
let text = "25"
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 206, weight: .ultraLight), .foregroundColor: mint]
let measured = text.size(withAttributes: attrs)
text.draw(at: NSPoint(x: (1024 - measured.width) / 2, y: (1024 - measured.height) / 2), withAttributes: attrs)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
