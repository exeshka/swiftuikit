import AVFoundation
import AppKit
import CoreImage
let a=CommandLine.arguments
let asset=AVURLAsset(url:URL(fileURLWithPath:a[1]))
let tr=asset.tracks(withMediaType:.video)[0]
let rd=try! AVAssetReader(asset:asset)
let o=AVAssetReaderTrackOutput(track:tr,outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA])
rd.add(o); rd.startReading()
let ctx=CIContext(); var i=0
let out=a[2]
while let s=o.copyNextSampleBuffer() {
  let t=CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(s))
  if let pb=CMSampleBufferGetImageBuffer(s) {
    let ci=CIImage(cvPixelBuffer:pb)
    let cg=ctx.createCGImage(ci,from:ci.extent)!
    let rep=NSBitmapImageRep(cgImage:cg)
    try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(out)/f\(String(format:"%04d",i)).png"))
    print(i,String(format:"%.4f",t))
  }
  i+=1
}
