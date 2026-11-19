import AppKit
let img = NSBitmapImageRep(data: NSData(contentsOfFile: CommandLine.arguments[1])! as Data)!.cgImage!
var px = [UInt8](repeating: 0, count: img.width * img.height * 4)
let ctx = CGContext(data: &px, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width * 4,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
func at(_ s: (Double, Double), _ i: Int) -> String {
    let cx = (20 + s.0 / 2) * 3, cy = (70 + Double(i) * 115 + s.1 / 2) * 3
    var a = [0.0, 0.0, 0.0]
    for dy in -4...4 { for dx in -4...4 { for c in 0..<3 { a[c] += Double(px[((Int(cy) + dy) * img.width + Int(cx) + dx) * 4 + c]) } } }
    return String(format: "%.0f", a[0] / 81)
}
print("small64: \(at((64, 64), 1))  large96: \(at((96, 96), 2))  large300: \(at((300, 90), 5))")
