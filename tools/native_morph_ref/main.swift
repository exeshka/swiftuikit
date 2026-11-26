// Native iOS 26 reference for glass buttons that morph into menus / popovers / dialogs. A navigation bar with a leading button
// and a trailing group of two buttons (one glass capsule): search opens a popover, compose is a Menu; the leading button asks a
// confirmationDialog. Launch args: "dark".
import SwiftUI

struct Root: View {
    @State private var pop = false
    @State private var confirm = false
    @State private var alert = false
    @State private var sheet = false
    @Namespace private var ns
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<40, id: \.self) { i in
                        HStack { Image(systemName: "bubble.left"); Text("Row \(i) — The quick brown fox"); Spacer() }
                            .padding(.vertical, 14).padding(.horizontal, 16)
                        Divider()
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { confirm = true } label: { Image(systemName: "line.3.horizontal") }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button { sheet = true } label: { Image(systemName: "plus") }
                        .matchedTransitionSource(id: "plus", in: ns)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { pop = true } label: { Image(systemName: "magnifyingglass") }
                    Menu {
                        Button("New chat", systemImage: "square.and.pencil") {}
                        Button("New folder", systemImage: "folder") {}
                        Divider()
                        Button("Delete all", systemImage: "trash", role: .destructive) { alert = true }
                    } label: { Image(systemName: "square.and.pencil") }
                }
            }
            .sheet(isPresented: $sheet) {
                List(0..<8, id: \.self) { Text("Row \($0)") }
                    .presentationDetents([.medium, .large])
                    .navigationTransition(.zoom(sourceID: "plus", in: ns))
            }
            .popover(isPresented: $pop) { Text("Popover content").padding().presentationCompactAdaptation(.popover) }
            .confirmationDialog("Choose", isPresented: $confirm) {
                Button("Duplicate") {}
                Button("Delete", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete all?", isPresented: $alert) { Button("Delete", role: .destructive) {}; Button("Cancel", role: .cancel) {} }
        }
        .preferredColorScheme(CommandLine.arguments.contains("dark") ? .dark : nil)
    }
}

@main struct App: SwiftUI.App { var body: some Scene { WindowGroup { Root() } } }
