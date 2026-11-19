import AppKit
let img = NSBitmapImageRep(data: NSData(contentsOfFile: CommandLine.arguments[1])! as Data)!.cgImage!
var px = [UInt8](repeating: 0, count: img.width * img.height * 4)
let ctx = CGContext(data: &px, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width * 4,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
let big = CommandLine.arguments.contains("big")
let rows: [(Double, Double)] = [(0, 0.5), (0.25, 0.5), (0.5, 0.5), (0.75, 0.5), (1, 0.5)]
for (i, r) in rows.enumerated() {
    let y = ((big ? 62 : 80) + Double(i) * 110 + (big ? 45 : 30)) * 3, x = 201.0 * 3
    var a = 0.0
    for dy in -6...6 { for dx in -6...6 { a += Double(px[((Int(y) + dy) * img.width + Int(x) + dx) * 4]) } }
    let out = a / 169
    let pred = 31 + 0.2235 * r.0 * 255
    print(String(format: "patch %.2f surround %.2f : native %5.1f  affine(local) %5.1f  diff %+5.1f", r.0, r.1, out, pred, out - pred))
}
