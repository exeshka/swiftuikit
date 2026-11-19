import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // EDR experiment (see lib/screens/edr_test_screen.dart)
    guard let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "EdrTest")?.messenger() else { return }
    let ch = FlutterMethodChannel(name: "ravel/edr", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      func flutterLayer() -> CALayer? {
        for scene in UIApplication.shared.connectedScenes {
          if let ws = scene as? UIWindowScene {
            for w in ws.windows { if let vc = w.rootViewController as? FlutterViewController { return vc.view.layer } }
          }
        }
        return nil
      }
      func set(_ on: Bool, _ l: CALayer?) {
        guard let l = l else { return }
        if #available(iOS 17.0, *) { l.wantsExtendedDynamicRangeContent = on }
        l.sublayers?.forEach { set(on, $0) }
      }
      func describe(_ l: CALayer?, _ d: Int = 0) -> String {
        guard let l = l else { return "(no layer)" }
        var edr = false
        if #available(iOS 17.0, *) { edr = l.wantsExtendedDynamicRangeContent }
        let m = l as? CAMetalLayer
        var s = String(repeating: " ", count: d) + "\(type(of: l)) edr=\(edr) fmt=\(m?.pixelFormat.rawValue ?? 0) cs=\(String(describing: m?.colorspace?.name))\n"
        for c in l.sublayers ?? [] { s += describe(c, d + 1) }
        return s
      }
      DispatchQueue.main.async {
        let layer = flutterLayer()
        func log(_ t: String) {
          let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("edr_log.txt")
          let line = "\(Date()) \(t)\n"
          if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() } else { try? line.write(to: url, atomically: true, encoding: .utf8) }
        }
        if call.method == "set", let on = call.arguments as? Bool {
          set(on, layer)
          log("set \(on)\n" + describe(layer))
          result(describe(layer))
        } else if call.method == "info" {
          var h = "n/a"
          if #available(iOS 16.0, *) { h = "current \(UIScreen.main.currentEDRHeadroom) potential \(UIScreen.main.potentialEDRHeadroom)" }
          log("info headroom " + h + "\n" + describe(layer))
          result("headroom " + h + "\n" + describe(layer))
        } else { result(FlutterMethodNotImplemented) }
      }
    }
  }
}
