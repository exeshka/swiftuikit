// Native iOS 26 reference for resizable sheets: `.sheet` with detents. Launch args: "medium" opens a [.medium, .large] sheet at
// once, "large" a large one, "custom" [.height(220), .fraction(0.6), .large], "interaction" a medium sheet that lets the page behind be
// used (presentationBackgroundInteraction), "form" a sheet with a nav bar and a list, "dark" forces dark appearance.
import SwiftUI
import UIKit

struct Content: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Sheet title").font(.title2.bold())
            Text("Drag the grabber to resize").foregroundStyle(.secondary)
            ForEach(0..<8, id: \.self) { i in
                Text("Row \(i)").frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                Divider()
            }
        }.padding()
    }
}

struct FormSheet: View {
    var body: some View {
        NavigationStack {
            List(0..<30, id: \.self) { Text("Filter \($0)") }
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button { } label: { Image(systemName: "xmark") } }
                    ToolbarItem(placement: .topBarTrailing) { Button("Done") {}.buttonStyle(.glassProminent) }
                }
                .safeAreaInset(edge: .bottom) {
                    Button { } label: { Text("Show 128 results").frame(maxWidth: .infinity) }
                        .buttonStyle(.glassProminent).controlSize(.large).padding(.horizontal, 16)
                }
        }
    }
}

struct Root: View {
    let args = CommandLine.arguments
    @State private var shown = false
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<40, id: \.self) { i in
                    (i % 2 == 0 ? Color.red : Color.blue).frame(height: 20)
                    Color(white: 0.08).frame(height: 20)
                }
            }.ignoresSafeArea()
            VStack { Button("Open sheet") { shown = true }.buttonStyle(.glassProminent).padding(.top, 100); Spacer() }
        }
        .preferredColorScheme(args.contains("dark") ? .dark : nil)
        .onAppear { if args.contains("medium") || args.contains("large") || args.contains("custom") || args.contains("interaction") || args.contains("form") || args.contains("small") { shown = true } }
        .sheet(isPresented: $shown) {
            Group {
                if args.contains("form") || args.contains("small") { FormSheet() } else { Content() }
            }
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(args.contains("interaction") ? .enabled : .automatic)
            .presentationBackground(args.contains("solid") ? AnyShapeStyle(Color(red: 28/255, green: 28/255, blue: 30/255)) : AnyShapeStyle(.regularMaterial))
        }
    }
    var detents: Set<PresentationDetent> {
        if args.contains("small") { return [.fraction(0.22), .large] }
        if args.contains("custom") { return [.height(220), .fraction(0.6), .large] }
        if args.contains("large") { return [.large] }
        return [.medium, .large]
    }
}

@main struct App: SwiftUI.App { var body: some Scene { WindowGroup { Root() } } }
