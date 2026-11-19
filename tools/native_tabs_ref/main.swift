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

struct Root: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            Tab("Inbox", systemImage: "tray", value: 0) { Page(title: "Inbox", hue: 0.58) }
            Tab("Tasks", systemImage: "checklist", value: 1) { Page(title: "Tasks", hue: 0.05) }
            Tab("Settings", systemImage: "gearshape", value: 2) { Page(title: "Settings", hue: 0.35) }
        }
        .preferredColorScheme(.dark)
    }
}

@main
struct RefTabsApp: App {
    var body: some Scene { WindowGroup { Root() } }
}
