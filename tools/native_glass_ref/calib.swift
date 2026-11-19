// usage: swift calib.swift native.png flutter.png bg.png
// Numeric comparison on the calibration picture (plates at x=51..351pt, y=[115,255,395,535,675] h=90).
import AppKit
func load(_ p: String) -> (w: Int, h: Int, px: [UInt8]) {
    let img = NSBitmapImageRep(data: NSData(contentsOfFile: p)! as Data)!.cgImage!
    let w = img.width, h = img.height
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    return (w, h, px)
}
let N = load(CommandLine.arguments[1]), F = load(CommandLine.arguments[2]), G = load(CommandLine.arguments[3])
func at(_ im: (w: Int, h: Int, px: [UInt8]), _ x: Int, _ y: Int) -> [Double] {
    let sx = Double(im.w) / 1206.0
    let xx = min(im.w - 1, Int(Double(x) * sx)), yy = min(im.h - 1, Int(Double(y) * sx))
    let i = (yy * im.w + xx) * 4
    return [Double(im.px[i]), Double(im.px[i+1]), Double(im.px[i+2])]
}
// mean over a (2r+1)^2 window, coordinates in 3x pixels
func mean(_ im: (w: Int, h: Int, px: [UInt8]), _ x: Int, _ y: Int, _ r: Int = 6) -> [Double] {
    var acc = [0.0, 0.0, 0.0]; var n = 0.0
    for dy in -r...r { for dx in -r...r { let v = at(im, x + dx, y + dy); for c in 0..<3 { acc[c] += v[c] }; n += 1 } }
    return acc.map { $0 / n }
}
func f(_ v: [Double]) -> String { String(format: "%3.0f %3.0f %3.0f", v[0], v[1], v[2]) }
let cy = [115.0, 255, 395, 535, 675].map { Int(($0 + 45) * 3) }

print("== A gray ramp: in -> out (native | flutter)")
for xpt in stride(from: 70, through: 340, by: 30) {
    let x = xpt * 3
    print(String(format: "x=%3d in %@ | N %@ | F %@", xpt, f(mean(G, x, cy[0])), f(mean(N, x, cy[0])), f(mean(F, x, cy[0]))))
}
print("== C swatches (center of each swatch inside plate)")
for i in 1...6 {
    let x = Int((Double(i) * 50.25 + 25) * 3)
    print("swatch \(i) in \(f(mean(G, x, cy[2]))) | N \(f(mean(N, x, cy[2]))) | F \(f(mean(F, x, cy[2])))")
}
print("== D step edge (x=201pt, white->black): profile across, N | F")
for dxpt in stride(from: -30, through: 30, by: 5) {
    let x = (201 + dxpt) * 3
    print(String(format: "dx=%3d  N %@ | F %@", dxpt, f(mean(N, x, cy[3], 2)), f(mean(F, x, cy[3], 2))))
}
print("== E flat (0.25 | 0.5 | 0.75): N | F")
for i in 0..<3 {
    let x = Int((Double(i) * 134 + 67) * 3)
    print("band \(i) in \(f(mean(G, x, cy[4]))) | N \(f(mean(N, x, cy[4]))) | F \(f(mean(F, x, cy[4])))")
}
print("== B checker: luminance std in plate interior (blur => lower)")
func std(_ im: (w: Int, h: Int, px: [UInt8])) -> Double {
    var vals = [Double]()
    for y in stride(from: cy[1] - 60, through: cy[1] + 60, by: 2) { for x in stride(from: 300, through: 900, by: 2) {
        let v = at(im, x, y); vals.append((v[0] + v[1] + v[2]) / 3) } }
    let m = vals.reduce(0, +) / Double(vals.count)
    return sqrt(vals.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(vals.count))
}
print(String(format: "bg std %.1f | N %.1f | F %.1f", std(G), std(N), std(F)))

print("== rim profile on flat band E (y=720pt), x from outside to inside; N | F | bg")
for xpt in stride(from: 40.0, through: 75.0, by: 1.5) {
    let x = Int(xpt * 3)
    print(String(format: "x=%5.1f  N %@ | F %@ | bg %@", xpt, f(mean(N, x, 720*3, 1)), f(mean(F, x, 720*3, 1)), f(mean(G, x, 720*3, 1))))
}
print("== shadow profile below plate E (x=200pt), y from plate bottom (765pt) down; N | F | bg")
for ypt in stride(from: 760.0, through: 800.0, by: 2.5) {
    print(String(format: "y=%5.1f  N %@ | F %@ | bg %@", ypt, f(mean(N, 200*3, Int(ypt*3), 1)), f(mean(F, 200*3, Int(ypt*3), 1)), f(mean(G, 200*3, Int(ypt*3), 1))))
}

print("== D rim step (white|black boundary 11pt inside the left rim at x=62): x=51..80, N | F")
for xpt in stride(from: 50.0, through: 80.0, by: 1.5) {
    print(String(format: "x=%5.1f  N %@ | F %@", xpt, f(mean(N, Int(xpt*3), cy[3], 1)), f(mean(F, Int(xpt*3), cy[3], 1))))
}

print("== D rim step right (black|white boundary at x=340, plate right rim at 351): x=325..352, N | F")
for xpt in stride(from: 325.0, through: 352.0, by: 1.5) {
    print(String(format: "x=%5.1f  N %@ | F %@", xpt, f(mean(N, Int(xpt*3), cy[3], 1)), f(mean(F, Int(xpt*3), cy[3], 1))))
}
