// usage: swift pts.swift native.png flutter.png bg.png  -> samples along the pill's center row
import AppKit
func load(_ p: String) -> (w: Int, h: Int, px: [UInt8]) {
    let img = NSBitmapImageRep(data: NSData(contentsOfFile: p)! as Data)!.cgImage!
    var px = [UInt8](repeating: 0, count: img.width * img.height * 4)
    let ctx = CGContext(data: &px, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
    return (img.width, img.height, px)
}
let N = load(CommandLine.arguments[1]), F = load(CommandLine.arguments[2]), G = load(CommandLine.arguments[3])
func m(_ im: (w: Int, h: Int, px: [UInt8]), _ xpt: Double, _ ypt: Double) -> String {
    var a = [0.0, 0.0, 0.0]; var n = 0.0
    for dy in -6...6 { for dx in -6...6 {
        let i = ((Int(ypt*3) + dy) * im.w + Int(xpt*3) + dx) * 4
        for c in 0..<3 { a[c] += Double(im.px[i+c]) }; n += 1 } }
    return String(format: "%3.0f %3.0f %3.0f", a[0]/n, a[1]/n, a[2]/n)
}
for y in [338.0, 360, 382] { for x in [175.0, 215, 255, 295, 335] {
    print(String(format: "(%3.0f,%3.0f) bg %@ | N %@ | F %@", x, y, m(G, x, y), m(N, x, y), m(F, x, y))) } }
