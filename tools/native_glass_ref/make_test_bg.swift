// Calibration picture (1206x2622): five bands, a plate of 300x90pt sits on each.
//  A gray ramp 0..1        -> tone curve of the glass
//  B fine checker (8pt)    -> blur strength + rim refraction
//  C color swatches        -> saturation / hue behaviour
//  D black|white step      -> blur kernel (edge response)
//  E mid-gray flat         -> pure tint level
import AppKit
let W = 1206, H = 2622, S = 3
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x*3, y: y*3, width: w*3, height: h*3) }
ctx.setFillColor(CGColor(gray: 0.12, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
// bands at y = 100, 240, 380, 520, 660 (each 120pt high, full width)
let bandY: [CGFloat] = [100, 240, 380, 520, 660]
// A ramp
for i in 0..<402 { ctx.setFillColor(CGColor(gray: CGFloat(i)/401, alpha: 1)); ctx.fill(rect(CGFloat(i), bandY[0], 1.01, 120)) }
// B checker
for cx in 0..<51 { for cy in 0..<15 {
    ctx.setFillColor(CGColor(gray: (cx + cy) % 2 == 0 ? 1 : 0, alpha: 1))
    ctx.fill(rect(CGFloat(cx)*8, bandY[1] + CGFloat(cy)*8, 8, 8)) } }
// C swatches
let sw: [(CGFloat,CGFloat,CGFloat)] = [(1,0,0),(0,1,0),(0,0,1),(0,1,1),(1,0,1),(1,1,0),(1,0.5,0),(0.5,0.5,0.5)]
for (i, c) in sw.enumerated() {
    ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1)); ctx.fill(rect(CGFloat(i)*50.25, bandY[2], 50.3, 120)) }
// D step
// black 0..62 | white 62..201 | black 201..340 | white 340..402: steps at 62 and 340 sit 11pt inside the plate rims
for (x0, x1, g) in [(0.0, 62.0, 0.0), (62.0, 201.0, 1.0), (201.0, 340.0, 0.0), (340.0, 402.0, 1.0)] {
    ctx.setFillColor(CGColor(gray: CGFloat(g), alpha: 1)); ctx.fill(rect(CGFloat(x0), bandY[3], CGFloat(x1 - x0), 120)) }
// E flat gray bands: 0.25 | 0.5 | 0.75
for (i, g) in [0.25, 0.5, 0.75].enumerated() {
    ctx.setFillColor(CGColor(gray: CGFloat(g), alpha: 1)); ctx.fill(rect(CGFloat(i)*134, bandY[4], 134.5, 120)) }
let img = ctx.makeImage()!
try! NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
