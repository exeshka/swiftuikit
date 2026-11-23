// Native iOS 26 reference for buttons: every SwiftUI button style, sizes, shapes, roles and states on a colourful backdrop, to
// compare with the kit's buttons. Launch arg "dark" forces the dark appearance; "page2" shows the second page.
import SwiftUI
import UIKit

struct Row<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 10) { content }
        }
    }
}

struct Page1: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Row(title: "bordered / borderedProminent / borderless / plain") {
                Button("Bordered") {}.buttonStyle(.bordered)
                Button("Prominent") {}.buttonStyle(.borderedProminent)
                Button("Borderless") {}.buttonStyle(.borderless)
                Button("Plain") {}.buttonStyle(.plain)
            }
            Row(title: "glass / glassProminent") {
                Button("Glass") {}.buttonStyle(.glass)
                Button("Prominent") {}.buttonStyle(.glassProminent)
                Button("Tinted") {}.buttonStyle(.glass).tint(.blue)
                Button("Tinted P") {}.buttonStyle(.glassProminent).tint(.orange)
            }
            Row(title: "shapes: capsule / roundedRect / circle") {
                Button("Capsule") {}.buttonStyle(.bordered).buttonBorderShape(.capsule)
                Button("Rounded") {}.buttonStyle(.bordered).buttonBorderShape(.roundedRectangle)
                Button { } label: { Image(systemName: "plus") }.buttonStyle(.bordered).buttonBorderShape(.circle)
                Button { } label: { Image(systemName: "plus") }.buttonStyle(.glass).buttonBorderShape(.circle)
                Button { } label: { Image(systemName: "plus") }.buttonStyle(.glassProminent).buttonBorderShape(.circle)
            }
            Row(title: "controlSize glass: mini small regular large extraLarge") {
                Button("mini") {}.buttonStyle(.glass).controlSize(.mini)
                Button("small") {}.buttonStyle(.glass).controlSize(.small)
                Button("regular") {}.buttonStyle(.glass)
                Button("large") {}.buttonStyle(.glass).controlSize(.large)
            }
            Row(title: "controlSize glassProminent") {
                Button("mini") {}.buttonStyle(.glassProminent).controlSize(.mini)
                Button("small") {}.buttonStyle(.glassProminent).controlSize(.small)
                Button("regular") {}.buttonStyle(.glassProminent)
                Button("large") {}.buttonStyle(.glassProminent).controlSize(.large)
            }
            Row(title: "extraLarge") {
                Button("Extra large") {}.buttonStyle(.glassProminent).controlSize(.extraLarge)
                Button("Glass XL") {}.buttonStyle(.glass).controlSize(.extraLarge)
            }
            Row(title: "bordered sizes") {
                Button("mini") {}.buttonStyle(.borderedProminent).controlSize(.mini)
                Button("small") {}.buttonStyle(.borderedProminent).controlSize(.small)
                Button("regular") {}.buttonStyle(.borderedProminent)
                Button("large") {}.buttonStyle(.borderedProminent).controlSize(.large)
            }
        }
    }
}

struct Page2: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Row(title: "roles: destructive / cancel") {
                Button("Delete", role: .destructive) {}.buttonStyle(.glass)
                Button("Delete", role: .destructive) {}.buttonStyle(.glassProminent)
                Button("Delete", role: .destructive) {}.buttonStyle(.borderedProminent)
                Button("Cancel", role: .cancel) {}.buttonStyle(.bordered)
            }
            Row(title: "disabled") {
                Button("Glass") {}.buttonStyle(.glass).disabled(true)
                Button("Prominent") {}.buttonStyle(.glassProminent).disabled(true)
                Button("Bordered") {}.buttonStyle(.borderedProminent).disabled(true)
            }
            Row(title: "icon + title") {
                Button { } label: { Label("Share", systemImage: "square.and.arrow.up") }.buttonStyle(.glass)
                Button { } label: { Label("Add", systemImage: "plus") }.buttonStyle(.glassProminent)
                Button { } label: { Label("Edit", systemImage: "pencil") }.buttonStyle(.bordered)
            }
            Row(title: "icon only: glass circles") {
                ForEach(["heart", "star", "magnifyingglass", "ellipsis"], id: \.self) { n in
                    Button { } label: { Image(systemName: n).frame(width: 22, height: 22) }
                        .buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                }
            }
            Row(title: "GlassEffectContainer: neighbours melt") {
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 8) {
                        Button { } label: { Image(systemName: "bold").frame(width: 22, height: 22) }.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                        Button { } label: { Image(systemName: "italic").frame(width: 22, height: 22) }.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                        Button { } label: { Image(systemName: "underline").frame(width: 22, height: 22) }.buttonStyle(.glass).buttonBorderShape(.circle).controlSize(.large)
                    }
                }
            }
            Row(title: "OPEN pill (messenger): borderedProminent mini capsule / glassProminent")  {
                Button("OPEN") {}.buttonStyle(.borderedProminent).buttonBorderShape(.capsule).controlSize(.small).tint(.blue)
                Button("OPEN") {}.buttonStyle(.glassProminent).controlSize(.small).tint(.blue)
                Button("GET") {}.buttonStyle(.glass).controlSize(.small).tint(.blue)
            }
            Row(title: "full width") {
                Button { } label: { Text("Continue").frame(maxWidth: .infinity) }.buttonStyle(.glassProminent).controlSize(.large)
            }
            Row(title: "full width bordered") {
                Button { } label: { Text("Continue").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large)
            }
        }
    }
}

enum Log {
    static var lines: [String] = []
    static func add(_ l: String) {
        lines.append(l)
        try? lines.joined(separator: "\n").write(toFile: NSHomeDirectory() + "/Documents/sizes.txt", atomically: true, encoding: .utf8)
    }
}

// `measure` mode: prints the size of every style x controlSize (text "Open" and an icon circle) to stdout
struct Measure: View {
    static let sizes: [(String, ControlSize)] = [("mini", .mini), ("small", .small), ("regular", .regular), ("large", .large), ("xl", .extraLarge)]
    static let styles = ["glass", "glassProminent", "bordered", "borderedProminent"]

    func button(_ style: String, _ size: ControlSize, circle: Bool) -> AnyView {
        let label: AnyView = circle ? AnyView(Image(systemName: "plus")) : AnyView(Text("Open"))
        let b = Button(action: {}) { label }
        var v: AnyView
        switch style {
        case "glass": v = AnyView(b.buttonStyle(.glass))
        case "glassProminent": v = AnyView(b.buttonStyle(.glassProminent))
        case "bordered": v = AnyView(b.buttonStyle(.bordered))
        default: v = AnyView(b.buttonStyle(.borderedProminent))
        }
        if circle { v = AnyView(v.buttonBorderShape(.circle)) }
        return AnyView(v.controlSize(size))
    }

    func measured(_ tag: String, _ v: AnyView) -> some View {
        v.background(GeometryReader { g in
            Color.clear.onAppear { Log.add("\(tag) \(String(format: "%.1f", g.size.width)) x \(String(format: "%.1f", g.size.height))") }
        })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Measure.styles, id: \.self) { style in
                    ForEach(Measure.sizes, id: \.0) { (name, size) in
                        HStack {
                            measured("\(style) \(name) text", button(style, size, circle: false))
                            measured("\(style) \(name) circle", button(style, size, circle: true))
                        }
                    }
                }
            }.padding()
        }
    }
}

struct Root: View {
    var body: some View {
        if CommandLine.arguments.contains("measure") { Measure() } else { gallery }
    }
    var gallery: some View {
        ZStack {
            LinearGradient(colors: [.red, .purple, .blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 0) {
                ForEach(0..<30, id: \.self) { i in
                    Color.white.opacity(i % 2 == 0 ? 0.18 : 0).frame(height: 18)
                    Color.clear.frame(height: 18)
                }
            }.ignoresSafeArea()
            ScrollView {
                if CommandLine.arguments.contains("page2") { Page2().padding(.horizontal, 20).padding(.top, 110) } else { Page1().padding(.horizontal, 20).padding(.top, 110) }
            }
        }
        .preferredColorScheme(CommandLine.arguments.contains("dark") ? .dark : nil)
    }
}

@main struct App: SwiftUI.App {
    var body: some Scene { WindowGroup { Root() } }
}
