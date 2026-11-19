// Adaptation test: rows with surround gray v2 and a patch v1 under a 200x60 pill.
import AppKit
let W = 1206, H = 2622
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x*3, y: y*3, width: w*3, height: h*3) }
ctx.setFillColor(CGColor(gray: 0.12, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
let rows: [(CGFloat, CGFloat)] = [(0, 0.5), (0.25, 0.5), (0.5, 0.5), (0.75, 0.5), (1, 0.5), (0.5, 0.5), (0.5, 0.5)]
for (i, r) in rows.enumerated() {
    let y = 60 + CGFloat(i) * 110
    ctx.setFillColor(CGColor(gray: r.1, alpha: 1)); ctx.fill(rect(0, y, 402, 100))
    ctx.setFillColor(CGColor(gray: r.0, alpha: 1)); ctx.fill(rect(31, y + 3, 340, 94))
}
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
