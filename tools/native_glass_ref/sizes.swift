import AppKit
let img = NSBitmapImageRep(data: NSData(contentsOfFile: CommandLine.arguments[1])! as Data)!.cgImage!
var px = [UInt8](repeating: 0, count: img.width * img.height * 4)
let ctx = CGContext(data: &px, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width * 4,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
let sizes: [(Double, Double)] = [(72, 72), (80, 80), (88, 88), (140, 72), (140, 80), (140, 88), (250, 80)]
var out = ""
for (i, s) in sizes.enumerated() {
    let cx = (20 + s.0 / 2) * 3, cy = (70 + Double(i) * 115 + s.1 / 2) * 3
    var a = 0.0
    for dy in -4...4 { for dx in -4...4 { a += Double(px[((Int(cy) + dy) * img.width + Int(cx) + dx) * 4]) } }
    out += String(format: "%.0fx%.0f:%.0f  ", s.0, s.1, a / 81)
}
print(out)
