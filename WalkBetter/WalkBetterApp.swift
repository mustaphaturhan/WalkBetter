import SwiftUI
import SwiftData

@main
struct WalkBetterApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                LocationList.self,
                Location.self
            ])

            let modelConfiguration = ModelConfiguration(
                isStoredInMemoryOnly: false
            )

            container = try ModelContainer(
                for: schema,
                configurations: modelConfiguration
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContainerView()
                .tint(.blue)
                .modelContainer(container)
        }
    }
}
