// usage: swift compare.swift native.png flutter.png bg.png out.png
// Side-by-side crops of each plate (native | flutter | background) + mean colors.
import AppKit
func load(_ p: String) -> CGImage { 
    let d = NSData(contentsOfFile: p)!
    return NSBitmapImageRep(data: d as Data)!.cgImage!
}
let a = load(CommandLine.arguments[1]), b = load(CommandLine.arguments[2]), g = load(CommandLine.arguments[3])
let plates: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
    ("circle", 40, 220, 96, 96), ("pill", 150, 330, 200, 60),
    ("squircle", 60, 470, 150, 150), ("card", 200, 600, 170, 90),
]
let m: CGFloat = 14, s: CGFloat = 3
func mean(_ img: CGImage, _ r: CGRect) -> (CGFloat, CGFloat, CGFloat) {
    let w = Int(r.width), h = Int(r.height)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: -r.minX, y: -(CGFloat(img.height) - r.maxY), width: CGFloat(img.width), height: CGFloat(img.height)))
    let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
    var R = 0.0, G = 0.0, B = 0.0
    for i in 0..<(w * h) { R += Double(p[i*4]); G += Double(p[i*4+1]); B += Double(p[i*4+2]) }
    let n = Double(w * h)
    return (CGFloat(R / n), CGFloat(G / n), CGFloat(B / n))
}
var rowH: [CGFloat] = plates.map { ($0.4 + 2 * m) * s }
let totalW = (170 + 2 * m) * s * 3 + 40, totalH = rowH.reduce(0, +) + 10 * CGFloat(plates.count)
let ctx = CGContext(data: nil, width: Int(1100), height: Int(totalH), bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 1100, height: totalH))
var y = totalH
for (i, p) in plates.enumerated() {
    let rect = CGRect(x: (p.1 - m) * s, y: (p.2 - m) * s, width: (p.3 + 2 * m) * s, height: (p.4 + 2 * m) * s)
    y -= rowH[i] + 10
    for (j, img) in [a, b, g].enumerated() {
        if let c = img.cropping(to: rect) {
            ctx.draw(c, in: CGRect(x: CGFloat(j) * ((170 + 2 * m) * s + 10), y: y, width: rect.width, height: rect.height))
        }
    }
    let inner = CGRect(x: (p.1 + p.3 * 0.25) * s, y: (p.2 + p.4 * 0.25) * s, width: p.3 * 0.5 * s, height: p.4 * 0.5 * s)
    let ma = mean(a, inner), mb = mean(b, inner), mg = mean(g, inner)
    func f(_ t: (CGFloat, CGFloat, CGFloat)) -> String { String(format: "(%3.0f %3.0f %3.0f)", t.0, t.1, t.2) }
    print("\(p.0): native \(f(ma))  flutter \(f(mb))  bg \(f(mg))")
}
let out = ctx.makeImage()!
try! NSBitmapImageRep(cgImage: out).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[4]))
