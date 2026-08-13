import SwiftUI

struct ContentView: View {
    @State private var enabledNavigationBar = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Native NavigationStack")
                        .font(.title2.bold())
                        .foregroundStyle(.black)

                    NavigationLink {
                        DetailView()
                    } label: {
                        Text("Go to red")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(.red, in: Capsule())
                    }

                    Button {
                        enabledNavigationBar.toggle()
                    } label: {
                        Text(
                            enabledNavigationBar
                                ? "Открыть второй экран"
                                : "Открыть второй эк"
                        )
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.75), in: Capsule())
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.white)
    }
}

struct DetailView: View {
    @State private var sliderValue = 0.35
    @State private var dragProgress = 0.25

    var body: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Red detail")
                    .font(.largeTitle.bold())

                Text("Попробуй закрыть страницу свайпом от края и из центра")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(1...6, id: \.self) { index in
                            Text("Card \(index)")
                                .font(.headline)
                                .frame(width: 150, height: 92)
                                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Native Slider")
                        .font(.headline)
                    Slider(value: $sliderValue)
                        .tint(.white)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Drag progress")
                        .font(.headline)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.black.opacity(0.18))
                            Capsule()
                                .fill(.white)
                                .frame(width: proxy.size.width * dragProgress)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    dragProgress = min(
                                        max(value.location.x / proxy.size.width, 0),
                                        1
                                    )
                                }
                        )
                    }
                    .frame(height: 28)
                }
                .padding(.horizontal, 24)
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView()
}
