// Native iOS 26 reference for the Flutter liquid glass: same background picture,
// same plate frames, real `.glassEffect`. Launch arg "clear" switches to .clear.
import SwiftUI
import UIKit

struct Plate: Identifiable {
    let id: String; let x: CGFloat; let y: CGFloat; let w: CGFloat; let h: CGFloat; let r: CGFloat?
}
let plates = [
    Plate(id: "circle", x: 40, y: 220, w: 96, h: 96, r: nil),
    Plate(id: "pill", x: 150, y: 330, w: 200, h: 60, r: nil),
    Plate(id: "squircle", x: 60, y: 470, w: 150, h: 150, r: 40),
    Plate(id: "card", x: 200, y: 600, w: 170, h: 90, r: 28),
]

let calib = CommandLine.arguments.contains("calib") || CommandLine.arguments.contains("adapt")
let adapt = CommandLine.arguments.contains("adapt")
let calibPlates: [Plate] = adapt
    ? (0..<5).map { Plate(id: "a\($0)", x: CommandLine.arguments.contains("big") ? 51 : 101, y: (CommandLine.arguments.contains("big") ? 62 : 80) + CGFloat($0) * 110,
                    w: CommandLine.arguments.contains("big") ? 300 : 200, h: CommandLine.arguments.contains("big") ? 90 : 60,
                    r: CommandLine.arguments.contains("rr") ? (CommandLine.arguments.contains("big") ? 28 : 29) : nil) }
    : [115.0, 255.0, 395.0, 535.0, 675.0].enumerated().map {
        Plate(id: "p\($0.offset)", x: 51, y: $0.element, w: 300, h: 90, r: 28) }

struct PlateView: View {
    let p: Plate
    let clear: Bool
    var body: some View {
        let label = Text(calib ? "" : p.id).font(.system(size: 14)).foregroundColor(.white)
            .frame(width: p.w, height: p.h)
        let g: Glass = clear ? .clear : .regular
        if let r = p.r {
            label.glassEffect(g, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        } else {
            label.glassEffect(g, in: Capsule())
        }
    }
}

// size test: uniform gray background (arg g<NN>) and plates of different sizes
let sizeTest = CommandLine.arguments.contains("size")
let sizeGray: Double = {
    for a in CommandLine.arguments where a.hasPrefix("g") && Int(a.dropFirst()) != nil { return Double(Int(a.dropFirst())!) / 100 }
    return 0.5
}()
let sizeList: [(CGFloat, CGFloat)] = [(44, 44), (64, 64), (96, 96), (120, 48), (200, 60), (300, 90), (360, 140)]

struct SizeTest: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: sizeGray).frame(width: 402, height: 874)
            ForEach(Array(sizeList.enumerated()), id: \.offset) { i, s in
                Color.clear.frame(width: s.0, height: s.1)
                    .glassEffect(.regular, in: s.0 == s.1 ? AnyShape(Circle()) : AnyShape(Capsule()))
                    .offset(x: 20, y: 70 + CGFloat(i) * 115)
            }
        }
        .frame(width: 402, height: 874, alignment: .topLeading).ignoresSafeArea()
    }
}

// morph test: pairs of 60pt circles at different gaps inside a GlassEffectContainer(spacing: 40)
let morphTest = CommandLine.arguments.contains("morph")
struct MorphTest: View {
    let gaps: [CGFloat] = [90, 60, 45, 35, 25, 15, 5, -10]
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.25), Color(white: 0.55)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 402, height: 874)
            ForEach(Array(gaps.enumerated()), id: \.offset) { i, g in
                GlassEffectContainer(spacing: 40) {
                    HStack(spacing: g) {
                        Color.clear.frame(width: 60, height: 60).glassEffect(.regular, in: Circle())
                        Color.clear.frame(width: 60, height: 60).glassEffect(.regular, in: Circle())
                    }
                }
                .offset(x: 200 - (120 + g) / 2, y: 60 + CGFloat(i) * 100)
            }
        }
        .frame(width: 402, height: 874, alignment: .topLeading).ignoresSafeArea()
    }
}

// interactive test: arg "inter" -> uniform gray bg with one interactive plate (hold with `simctl` long tap)
// arg "trans" -> a button toggles plates inside a GlassEffectContainer with glassEffectTransition
let interTest = CommandLine.arguments.contains("inter")
struct InterTest: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: sizeGray).frame(width: 402, height: 874)
            Button(action: {}) { Text("Glass button").frame(width: 200, height: 80) }
                .buttonStyle(.glass)
                .offset(x: 101, y: 300)
            ForEach(Array([28.0, 36.0, 44.0, 60.0].enumerated()), id: \.offset) { i, c in
                Button(action: {}) { Image(systemName: "plus").font(.system(size: 18)).frame(width: c, height: c) }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .offset(x: 30 + CGFloat(i) * 90, y: 560)
            }
        }
        .frame(width: 402, height: 874, alignment: .topLeading).ignoresSafeArea()
    }
}

let transTest = CommandLine.arguments.contains("trans")
struct TransTest: View {
    @State var on = true
    @Namespace var ns
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.25), Color(white: 0.6)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 402, height: 874)
            GlassEffectContainer(spacing: 40) {
                HStack(spacing: 20) {
                    Color.clear.frame(width: 80, height: 80).glassEffect(.regular, in: Circle()).glassEffectID("a", in: ns)
                    if on {
                        Color.clear.frame(width: 80, height: 80).glassEffect(.regular, in: Circle()).glassEffectID("b", in: ns)
                    }
                }
            }.offset(x: 100, y: 300)
            Color.red.opacity(0.01).frame(width: 402, height: 874)
                .onTapGesture { withAnimation(.smooth(duration: 1.5)) { on.toggle() } }
        }
        .frame(width: 402, height: 874, alignment: .topLeading).ignoresSafeArea()
    }
}

// grid test: white bg with black lines, tinted plates at the same spots as the Flutter "Liquid glass grid" screen
let gridTest = CommandLine.arguments.contains("grid")
struct GridTest: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                var x: CGFloat = 0; var i = 0
                while x <= size.width { var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); ctx.stroke(p, with: .color(.black), lineWidth: i % 5 == 0 ? 3 : 1); x += 20; i += 1 }
                var y: CGFloat = 0; i = 0
                while y <= size.height { var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); ctx.stroke(p, with: .color(.black), lineWidth: i % 5 == 0 ? 3 : 1); y += 20; i += 1 }
            }.frame(width: 402, height: 874)
            Color.clear.frame(width: 96, height: 96).glassEffect(.regular.tint(Color(red: 1, green: 0.23, blue: 0.19).opacity(0.35)), in: Circle()).offset(x: 40, y: 180)
            Color.clear.frame(width: 200, height: 60).glassEffect(.regular.tint(Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.35)), in: Capsule()).offset(x: 60, y: 360)
            Color.clear.frame(width: 120, height: 120).glassEffect(.regular.tint(Color(red: 1, green: 0.84, blue: 0.04).opacity(0.35)), in: RoundedRectangle(cornerRadius: 36, style: .continuous)).offset(x: 230, y: 460)
            Color.clear.frame(width: 96, height: 96).glassEffect(.regular, in: Circle()).offset(x: 40, y: 560)
        }
        .frame(width: 402, height: 874, alignment: .topLeading).ignoresSafeArea()
    }
}

// nav bar references: arg "nav" + one of large | inline | inlinelarge | subtitle
let navTest = CommandLine.arguments.contains("nav")
struct NavTest: View {
    let mode: String
    // tap search: its icon swaps; tap compose: a third action appears / leaves (same behaviour as the Flutter demo)
    @State private var swapped = false
    @State private var third = false
    var body: some View {
        NavigationStack {
            List(0..<(CommandLine.arguments.contains("empty") ? 0 : 60), id: \.self) { i in
                HStack { Image(systemName: "bubble.left"); Text("Row \(i) — The quick brown fox") }
            }
            .navigationTitle(CommandLine.arguments.contains("long") ? "A very long conversation title that cannot fit" : "Library")
            .modifier(DisplayMod(mode: mode))
            .modifier(SubtitleMod(on: mode == "subtitle" || CommandLine.arguments.contains("sub")))
            .modifier(InlineLargeMod(on: mode == "inlinelarge"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { } label: { Image(systemName: "line.3.horizontal") } }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { withAnimation { swapped.toggle() } } label: { ZStack { if swapped { Image(systemName: "checklist").transition(.blurReplace) } else { Image(systemName: "magnifyingglass").transition(.blurReplace) } } }
                    Button { withAnimation { third.toggle() } } label: { Image(systemName: "square.and.pencil") }
                    if third { Button { } label: { Image(systemName: "pencil") } }
                }
            }
        }
    }
}
struct DisplayMod: ViewModifier {
    let mode: String
    func body(content: Content) -> some View {
        if mode == "large" || mode == "subtitle" { content.navigationBarTitleDisplayMode(.large) }
        else if mode == "inlinelarge" { content }
        else { content.navigationBarTitleDisplayMode(.inline) }
    }
}
struct SubtitleMod: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View { if on { content.navigationSubtitle("60 items") } else { content } }
}
struct InlineLargeMod: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View { if on { content.toolbarTitleDisplayMode(.inlineLarge) } else { content } }
}

// center test: one 44 pt glass circle button in the middle of a black screen (arg "center")
let centerTest = CommandLine.arguments.contains("center")
struct CenterTest: View {
    var body: some View {
        ZStack {
            Color.black
            Button(action: {}) { Image(systemName: "plus").font(.system(size: 14)).frame(width: 31, height: 31) }
                .buttonStyle(.glass).buttonBorderShape(.circle)
        }.frame(width: 402, height: 874).ignoresSafeArea()
    }
}

// input test (arg "input"): a chat composer with liquid glass: a plus circle and a capsule text field with a send button
let inputTest = CommandLine.arguments.contains("input")
struct InputTest: View {
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<30, id: \.self) { i in
                        Text("Message \(i) — The quick brown fox jumps over the lazy dog")
                            .padding(12).background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 18))
                    }
                }.padding()
            }
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button { } label: { Image(systemName: "plus").font(.system(size: 20)).frame(width: 44, height: 44) }
                        .buttonStyle(.glass).buttonBorderShape(.circle)
                    HStack(spacing: 8) {
                        TextField("Message", text: $text, axis: .vertical).lineLimit(1...5).focused($focused)
                        if !text.isEmpty {
                            Button { text = "" } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 28)) }
                        } else {
                            Image(systemName: "mic").font(.system(size: 20)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }.padding(.horizontal, 12).padding(.bottom, 8)
        }
    }
}

// dock test (arg "dock"): a TabView (floating glass tab bar) with a composer and floating chips in a bottom safe-area inset
let dockTest = CommandLine.arguments.contains("dock")
struct DockTest: View {
    @State private var text = ""
    @State private var tab = 0
    @FocusState private var focused: Bool
    var body: some View {
        TabView(selection: $tab) {
            Tab("Chats", systemImage: "bubble.left", value: 0) { page }
            Tab("Tasks", systemImage: "checklist", value: 1) { Color.black }
            Tab("Files", systemImage: "square.on.square", value: 2) { Color.black }
        }
        .preferredColorScheme(.dark)
    }
    var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<30, id: \.self) { i in
                    Text("Message \(i) — The quick brown fox jumps over the lazy dog")
                        .padding(12).background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 18))
                }
            }.padding()
        }
        .background(Color.black)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(["Summarize", "Translate", "Explain"], id: \.self) { l in
                        Button(l) { }.buttonStyle(.glass)
                    }
                    Spacer()
                }.padding(.horizontal, 12)
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button { } label: { Image(systemName: "plus").font(.system(size: 20)).frame(width: 44, height: 44) }
                            .buttonStyle(.glass).buttonBorderShape(.circle)
                        HStack(spacing: 8) {
                            TextField("Message", text: $text, axis: .vertical).lineLimit(1...5).focused($focused)
                            Image(systemName: "mic").font(.system(size: 20)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }.padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
    }
}

// switch test (arg "switch"): native iOS 26 toggles on a dark and a gray background
let switchTest = CommandLine.arguments.contains("switch")
struct SwitchTest: View {
    @State private var a = true
    @State private var b = false
    @State private var c = true
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 40) {
                Toggle("Wi-Fi", isOn: $a)
                Toggle("Bluetooth", isOn: $b)
                Toggle("Airplane", isOn: $c).tint(.orange)
            }.padding(40).preferredColorScheme(.dark)
        }
    }
}


// controls test (arg "controls"): native segmented control + slider over the photo; arg "swipe": a list with swipe actions
let ctrlTest = CommandLine.arguments.contains("controls")
let swipeTest = CommandLine.arguments.contains("swipe")
let whiteTest = CommandLine.arguments.contains("white")
struct CtrlTest: View {
    @State private var seg = 0
    @State private var v = 0.4
    @State private var v2 = 0.7
    var body: some View {
        ZStack {
            if whiteTest { Color.white.ignoresSafeArea() } else {
            Image(uiImage: UIImage(contentsOfFile: Bundle.main.path(forResource: "bg", ofType: "png")!)!)
                .resizable().scaledToFill().frame(width: 402, height: 874).clipped().ignoresSafeArea() }
            VStack(spacing: 48) {
                Picker("", selection: $seg) { Text("All").tag(0); Text("Unread").tag(1); Text("Flagged").tag(2) }.pickerStyle(.segmented)
                Slider(value: $v)
                Slider(value: $v2, in: 0...1, step: 0.1)
            }.padding(24)
        }.preferredColorScheme(whiteTest ? .light : .dark)
    }
}
struct SwipeTest: View {
    @State private var items = ["Inbox", "Drafts", "Sent", "Archive"]
    var body: some View {
        List {
            Section("Mailboxes") {
                ForEach(items, id: \.self) { e in
                    Text(e).swipeActions(edge: .leading) {
                        Button { } label: { Text("Pin") }.tint(.blue)
                        Button { } label: { Text("Read") }.tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { items.removeAll { $0 == e } } label: { Text("Delete") }
                        Button { } label: { Text("Flag") }.tint(.orange)
                    }
                }
            }
        }.listStyle(.insetGrouped).preferredColorScheme(.dark)
    }
}

struct ContentView: View {
    let clear = CommandLine.arguments.contains("clear")
    var body: some View {
        if ctrlTest { CtrlTest() } else if swipeTest { SwipeTest() } else if switchTest { SwitchTest() } else if dockTest { DockTest() } else if inputTest { InputTest() } else if centerTest { CenterTest() } else if navTest { NavTest(mode: (["large", "inline", "inlinelarge", "subtitle"].first { CommandLine.arguments.contains($0) }) ?? "large") } else if gridTest { GridTest() } else if interTest { InterTest() } else if transTest { TransTest() } else if morphTest { MorphTest() } else if sizeTest { SizeTest() } else { main }
    }
    var main: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: UIImage(contentsOfFile: Bundle.main.path(forResource: adapt ? "adapt" : (calib ? "calib" : "bg"), ofType: "png")!)!)
                .resizable().scaledToFill()
                .frame(width: 402, height: 874).clipped()
            ForEach(calib ? calibPlates : plates) { p in
                PlateView(p: p, clear: clear).offset(x: p.x, y: p.y)
            }
        }
        .frame(width: 402, height: 874, alignment: .topLeading)
        .ignoresSafeArea()
    }
}

@main struct RefApp: App {
    var body: some Scene { WindowGroup { ContentView().ignoresSafeArea() } }
}
