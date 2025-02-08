import SwiftUI
import SwiftData

struct ContainerView: View {
    @State private var isActive = false
    @State private var size = 0.7
    @State private var opacity = 0.3

    var body: some View {
        if isActive {
            LocationListsView()
        } else {
            VStack(spacing: 24) {
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.bounce, options: .repeating)

                Text("WalkBetter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue.gradient)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContainerView()
        .modelContainer(for: LocationList.self, inMemory: true)
}
