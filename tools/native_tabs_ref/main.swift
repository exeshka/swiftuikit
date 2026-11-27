// Native iOS 26 reference for the page switcher: a TabView, every tab its own NavigationStack with a large title, so the
// tab switch and the headers can be recorded and compared with SwiftUiPageSwitcher. Launch arg "scrolled" starts tab 1
// scrolled down (its title collapsed) to see what a switch does to a collapsed header.
import SwiftUI
import UIKit

struct Page: View {
    let title: String
    let hue: Double
    var body: some View {
        NavigationStack {
            List(0..<40, id: \.self) { i in
                Text("\(title) row \(i)")
                    .listRowBackground(Color(hue: (hue + Double(i) * 0.01).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.45))
                    .foregroundColor(.white)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { } label: { Image(systemName: "magnifyingglass") }
                    Button { } label: { Image(systemName: "square.and.pencil") }
                }
            }
        }
    }
}

// Launch args: "light" (light theme), "five" (5 tabs instead of 3), "min" (tabBarMinimizeBehavior .onScrollDown).
let args = CommandLine.arguments
struct Root: View {
    @State private var tab = 0
    var body: some View {
        let tv0 = TabView(selection: $tab) {
            Tab("Inbox", systemImage: "tray", value: 0) { Page(title: "Inbox", hue: 0.58) }
            Tab("Tasks", systemImage: "checklist", value: 1) { Page(title: "Tasks", hue: 0.05) }
            Tab("Settings", systemImage: "gearshape", value: 2) { Page(title: "Settings", hue: 0.35) }
            if args.contains("five") {
                Tab("Map", systemImage: "map", value: 3) { Page(title: "Map", hue: 0.8) }
                Tab("Profile", systemImage: "person", value: 4) { Page(title: "Profile", hue: 0.15) }
            }
        }
        .preferredColorScheme(args.contains("light") ? .light : .dark)
        // "acc": tabViewBottomAccessory (a mini player); inline placement shows the compact version only
        let tv = args.contains("acc") ? AnyView(tv0.tabViewBottomAccessory { Player() }) : AnyView(tv0)
        if args.contains("min") { tv.tabBarMinimizeBehavior(.onScrollDown) } else { tv }
    }
}

struct Player: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note").frame(width: 32, height: 32)
            if placement != .inline {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Now Playing").font(.subheadline).bold()
                    Text("Artist").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            } else { Text("Playing").font(.subheadline); Spacer() }
            Image(systemName: "play.fill")
            if placement != .inline { Image(systemName: "forward.fill") }
        }.padding(.horizontal, 12)
    }
}

@main
struct RefTabsApp: App {
    var body: some Scene { WindowGroup { Root() } }
}
