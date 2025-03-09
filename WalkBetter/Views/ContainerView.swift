import SwiftUI
import SwiftData

struct ContainerView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            LocationListsView()
        } else {
            SplashScreenView(onComplete: {
                self.isActive = true
            })
        }
    }
}

#Preview {
    ContainerView()
        .modelContainer(for: LocationList.self, inMemory: true)
}
