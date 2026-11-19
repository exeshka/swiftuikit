// Native iOS 26 reference for a sheet: a striped page with a button that presents a system `.sheet`, to look at how the page
// BEHIND it moves (scale, offset, corner radius). Launch arg "present" opens the sheet at once.
import SwiftUI
import UIKit

struct Root: View {
    @State private var shown = CommandLine.arguments.contains("present")
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<40, id: \.self) { i in
                    (i % 2 == 0 ? Color.red : Color.blue).frame(height: 20)
                    Color(white: 0.07).frame(height: 20)
                }
            }
            .ignoresSafeArea()
            Button("Open") { shown = true }
                .padding(.top, 120).padding(.leading, 40)
        }
        .sheet(isPresented: $shown) {
            ZStack { Color.black.ignoresSafeArea(); Text("sheet").foregroundColor(.white) }
                .presentationDetents([.large])
        }
    }
}

@main struct App: SwiftUI.App {
    var body: some Scene { WindowGroup { Root() } }
}
