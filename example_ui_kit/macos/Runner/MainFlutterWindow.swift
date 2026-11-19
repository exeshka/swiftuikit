import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // EDR experiment (see lib/screens/edr_test_screen.dart)
    let ch = FlutterMethodChannel(name: "ravel/edr", binaryMessenger: flutterViewController.engine.binaryMessenger)
    ch.setMethodCallHandler { call, result in
      func set(_ on: Bool, _ l: CALayer?) {
        guard let l = l else { return }
        if #available(macOS 14.0, *) { l.wantsExtendedDynamicRangeContent = on }
        l.sublayers?.forEach { set(on, $0) }
      }
      func edrFlag(_ l: CALayer) -> Bool { if #available(macOS 14.0, *) { return l.wantsExtendedDynamicRangeContent }; return false }
      func describe(_ l: CALayer?, _ d: Int = 0) -> String {
        guard let l = l else { return "" }
        var s = String(repeating: " ", count: d) + "\(type(of: l)) edr=\(edrFlag(l)) cs=\(String(describing: (l as? CAMetalLayer)?.colorspace)) fmt=\((l as? CAMetalLayer)?.pixelFormat.rawValue ?? 0)\n"
        for c in l.sublayers ?? [] { s += describe(c, d + 1) }
        return s
      }
      let layer = flutterViewController.view.layer
      if call.method == "set", let on = call.arguments as? Bool {
        set(on, layer)
        result(describe(layer))
      } else if call.method == "info" {
        let s = NSScreen.main
        result("headroom now \(s?.maximumExtendedDynamicRangeColorComponentValue ?? 0) potential \(s?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 0)\n" + describe(layer))
      } else { result(FlutterMethodNotImplemented) }
    }

    super.awakeFromNib()
  }
}
