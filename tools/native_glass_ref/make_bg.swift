// Renders the shared background picture (1206x2622, iPhone @3x) used by both
// the Flutter playground and the native SwiftUI reference app.
import AppKit
import CoreGraphics

let W = 1206, H = 2622
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// flip to top-left origin
ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)

func col(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: a)
}
let grad = CGGradient(colorsSpace: cs,
    colors: [col(0x1B1464), col(0xC1367A), col(0xFF9A44), col(0xFFE29A)] as CFArray,
    locations: [0, 0.35, 0.6, 0.72])!
ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: H), options: [])

// sun
let sunC = CGPoint(x: CGFloat(W) * 0.68, y: CGFloat(H) * 0.5)
let sun = CGGradient(colorsSpace: cs, colors: [col(0xFFFFFF), col(0xFFE29A, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(sun, startCenter: sunC, startRadius: 0, endCenter: sunC, endRadius: 270, options: [])

// mountains
for layer in 0..<3 {
    ctx.beginPath(); ctx.move(to: CGPoint(x: 0, y: H))
    let base = CGFloat(H) * (0.62 + CGFloat(layer) * 0.06)
    var x: CGFloat = 0
    while x <= CGFloat(W) + 60 {
        let y = base - (sin(x / (180 + CGFloat(layer) * 75) + CGFloat(layer)) * 120 + CGFloat((Int(x) * 37 + layer * 11) % 54)) - 120 + CGFloat(layer) * 42
        ctx.addLine(to: CGPoint(x: x, y: y)); x += 60
    }
    ctx.addLine(to: CGPoint(x: W, y: H)); ctx.closePath()
    let t = CGFloat(layer) / 2
    ctx.setFillColor(CGColor(red: (0x2D + (0x0B - 0x2D) * t) / 255, green: (0x1B + (0x08 - 0x1B) * t) / 255,
                             blue: (0x4E + (0x20 - 0x4E) * t) / 255, alpha: 1))
    ctx.fillPath()
}

// grid every 24pt
ctx.setStrokeColor(col(0xFFFFFF, 0.25)); ctx.setLineWidth(3)
var gx = 0; while gx < W { ctx.move(to: CGPoint(x: gx, y: 0)); ctx.addLine(to: CGPoint(x: gx, y: H)); gx += 72 }
var gy = 0; while gy < H { ctx.move(to: CGPoint(x: 0, y: gy)); ctx.addLine(to: CGPoint(x: W, y: gy)); gy += 72 }
ctx.strokePath()

// text rows
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
for i in 0..<14 {
    let size = CGFloat(15 + (i % 3) * 3) * 3
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: .bold),
        .foregroundColor: NSColor(white: 1, alpha: 0.85),
    ]
    let s = "LIQUID GLASS " + String(repeating: "refraction ", count: 4)
    s.draw(at: CGPoint(x: CGFloat(-30 * (i % 4)) * 3, y: CGFloat(110 + i * 52) * 3), withAttributes: attrs)
}

// dots (deterministic)
var seed: UInt64 = 12345
func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat((seed >> 33) % 10000) / 10000 }
ctx.setFillColor(col(0x00E5FF))
for _ in 0..<40 {
    let r = (3 + rnd() * 4) * 3
    ctx.fillEllipse(in: CGRect(x: rnd() * CGFloat(W) - r, y: rnd() * CGFloat(H) - r, width: r * 2, height: r * 2))
}

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
