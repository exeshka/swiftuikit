// usage: swift crop.swift a.png b.png x y w h zoom out.png   (pt units; side by side a | b)
import AppKit
let args = CommandLine.arguments
func load(_ p: String) -> CGImage { NSBitmapImageRep(data: NSData(contentsOfFile: p)! as Data)!.cgImage! }
let a = load(args[1]), b = load(args[2])
let x = Double(args[3])!, y = Double(args[4])!, w = Double(args[5])!, h = Double(args[6])!, z = Double(args[7])!
let r = CGRect(x: x*3, y: y*3, width: w*3, height: h*3)
let ow = Int(w*3*z), oh = Int(h*3*z)
let ctx = CGContext(data: nil, width: ow*2+8, height: oh, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .none
ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: ow*2+8, height: oh))
for (i, im) in [a, b].enumerated() { ctx.draw(im.cropping(to: r)!, in: CGRect(x: i*(ow+8), y: 0, width: ow, height: oh)) }
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[8]))
