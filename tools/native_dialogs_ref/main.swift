// Native iOS 26 reference for dialogs. Launch args: "alert" (title, message, OK + Cancel), "alert3" (three buttons), "alertdestr"
// (a destructive button), "alertfield" (a text field), "alertshort" (title only, one button), "confirm" (confirmationDialog from a
// button, with title and message), "confirmnotitle", "dark" forces dark appearance.
import SwiftUI
import UIKit

struct Root: View {
    let args = CommandLine.arguments
    @State private var alert = false
    @State private var confirm = false
    @State private var text = ""
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<40, id: \.self) { i in
                    (i % 2 == 0 ? Color.red : Color.blue).frame(height: 20)
                    Color(white: 0.08).frame(height: 20)
                }
            }.ignoresSafeArea()
            VStack(spacing: 20) {
                Button("Open dialog") { alert = true; confirm = true }.buttonStyle(.glassProminent).padding(.top, 100)
                Spacer()
            }
        }
        .preferredColorScheme(args.contains("dark") ? .dark : nil)
        .onAppear {
            if args.contains("confirm") || args.contains("confirmnotitle") { confirm = true } else if args.contains("alert") || args.contains("alert3") || args.contains("alertdestr") || args.contains("alertfield") || args.contains("alertshort") || args.contains("alertpref") || args.contains("alerttint") { alert = true }
        }
        .alert(args.contains("alertshort") ? "Saved" : "Delete the file?", isPresented: Binding(get: { alert && !args.contains("confirm") && !args.contains("confirmnotitle") }, set: { alert = $0 })) {
            if args.contains("alertfield") { TextField("Name", text: $text) }
            if args.contains("alertshort") {
                Button("OK") {}
            } else if args.contains("alert3") {
                Button("Keep both") {}
                Button("Replace") {}
                Button("Cancel", role: .cancel) {}
            } else if args.contains("alertpref") {
                Button("Delete", role: .destructive) {}
                Button("Save") {}.keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) {}
            } else if args.contains("alerttint") {
                Button("Share") {}.tint(.green)
                Button("Cancel", role: .cancel) {}
            } else if args.contains("alertdestr") {
                Button("Delete", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK") {}
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if !args.contains("alertshort") { Text("This cannot be undone. The file will be removed from every device.") }
        }
        .confirmationDialog(args.contains("confirmnotitle") ? "" : "Choose an action", isPresented: Binding(get: { confirm && (args.contains("confirm") || args.contains("confirmnotitle")) }, set: { confirm = $0 }), titleVisibility: args.contains("confirmnotitle") ? .hidden : .visible) {
            Button("Duplicate") {}
            Button("Move to folder") {}
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: { Text("Pick what to do with the selected items.") }
    }
}

@main struct App: SwiftUI.App { var body: some Scene { WindowGroup { Root() } } }
