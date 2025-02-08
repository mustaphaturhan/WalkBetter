import SwiftData
import SwiftUI
import MapKit

enum PreviewHelperService {
    static func createPreviewContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: LocationList.self, configurations: config)
    }

    static func previewWithNetworkState<Content: View>(
        isConnected: Bool = true,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .environment(\.networkService, NetworkConnectivityService.preview(isConnected: isConnected))
    }

    static func previewWithContainer<Content: View>(
        isConnected: Bool = true,
        @ViewBuilder content: (ModelContainer) throws -> Content
    ) -> AnyView {
        do {
            let container = try createPreviewContainer()
            return try content(container)
                .modelContainer(container)
                .environment(\.networkService, NetworkConnectivityService.preview(isConnected: isConnected))
                .eraseToAnyView()
        } catch {
            return Text("Failed to create preview: \(error.localizedDescription)")
                .eraseToAnyView()
        }
    }

    static func createSampleList(in context: ModelContext, name: String = "Ankara Tour", withLocations: Bool = true) -> LocationList {
        let list = LocationList(name: name)

        if withLocations {
            let locations = [
                Location(name: "Kuğulu Park", latitude: 39.9020, longitude: 32.8602, order: 0),
                Location(name: "Anıtkabir", latitude: 39.9255, longitude: 32.8378, order: 1),
                Location(name: "Seğmenler Parkı", latitude: 39.8941, longitude: 32.8626, order: 2),
                Location(name: "İşler kitapevi", latitude: 39.9148, longitude: 32.8550, order: 3),
                Location(name: "Güvenpark", latitude: 39.9196, longitude: 32.8533, order: 4)
            ]

            locations.forEach { location in
                location.list = list
                list.locations.append(location)
            }
        }

        context.insert(list)
        return list
    }

    static func createBrusselsList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "Brussels Tour")

        let locations = [
            Location(name: "Grand Place", latitude: 50.8467, longitude: 4.3499, order: 0),
            Location(name: "Palace of Justice", latitude: 50.8354, longitude: 4.3490, order: 1),
            Location(name: "Royal Palace", latitude: 50.8429, longitude: 4.3523, order: 2),
            Location(name: "Louise", latitude: 50.8388, longitude: 4.3563, order: 3),
            Location(name: "Atomium", latitude: 50.8947, longitude: 4.3413, order: 4)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        list.isOptimized = true
        context.insert(list)
        return list
    }

    static func createParisList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "Paris Highlights")

        let locations = [
            Location(name: "Eiffel Tower", latitude: 48.8584, longitude: 2.2945, order: 0),
            Location(name: "Louvre Museum", latitude: 48.8606, longitude: 2.3376, order: 1),
            Location(name: "Notre-Dame", latitude: 48.8530, longitude: 2.3499, order: 2),
            Location(name: "Arc de Triomphe", latitude: 48.8738, longitude: 2.2950, order: 3),
            Location(name: "Sacré-Cœur", latitude: 48.8867, longitude: 2.3431, order: 4),
            Location(name: "Musée d'Orsay", latitude: 48.8600, longitude: 2.3266, order: 5)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        context.insert(list)
        return list
    }

    // New sample lists
    static func createLondonList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "London Walking Tour")

        let locations = [
            Location(name: "Big Ben", latitude: 51.5007, longitude: -0.1246, order: 0),
            Location(name: "Tower Bridge", latitude: 51.5055, longitude: -0.0754, order: 1),
            Location(name: "British Museum", latitude: 51.5194, longitude: -0.1270, order: 2),
            Location(name: "Buckingham Palace", latitude: 51.5014, longitude: -0.1419, order: 3),
            Location(name: "St Paul's Cathedral", latitude: 51.5138, longitude: -0.0984, order: 4),
            Location(name: "Trafalgar Square", latitude: 51.5080, longitude: -0.1281, order: 5),
            Location(name: "Covent Garden", latitude: 51.5117, longitude: -0.1240, order: 6)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        context.insert(list)
        return list
    }

    static func createRomeList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "Rome Classics")

        let locations = [
            Location(name: "Colosseum", latitude: 41.8902, longitude: 12.4922, order: 0),
            Location(name: "Trevi Fountain", latitude: 41.9009, longitude: 12.4833, order: 1),
            Location(name: "Pantheon", latitude: 41.8986, longitude: 12.4769, order: 2),
            Location(name: "Spanish Steps", latitude: 41.9058, longitude: 12.4823, order: 3),
            Location(name: "Vatican Museums", latitude: 41.9064, longitude: 12.4534, order: 4),
            Location(name: "St. Peter's Basilica", latitude: 41.9022, longitude: 12.4533, order: 5),
            Location(name: "Piazza Navona", latitude: 41.8991, longitude: 12.4730, order: 6),
            Location(name: "Roman Forum", latitude: 41.8925, longitude: 12.4853, order: 7)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        context.insert(list)
        return list
    }

    static func createAmsterdamList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "Amsterdam Canals")

        let locations = [
            Location(name: "Dam Square", latitude: 52.3731, longitude: 4.8922, order: 0),
            Location(name: "Anne Frank House", latitude: 52.3752, longitude: 4.8840, order: 1),
            Location(name: "Rijksmuseum", latitude: 52.3600, longitude: 4.8852, order: 2),
            Location(name: "Van Gogh Museum", latitude: 52.3584, longitude: 4.8811, order: 3),
            Location(name: "Royal Palace", latitude: 52.3731, longitude: 4.8913, order: 4),
            Location(name: "Vondelpark", latitude: 52.3579, longitude: 4.8686, order: 5)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        context.insert(list)
        return list
    }

    static func createIstanbulList(in context: ModelContext) -> LocationList {
        let list = LocationList(name: "Istanbul Heritage")

        let locations = [
            Location(name: "Hagia Sophia", latitude: 41.0086, longitude: 28.9802, order: 0),
            Location(name: "Blue Mosque", latitude: 41.0054, longitude: 28.9768, order: 1),
            Location(name: "Topkapi Palace", latitude: 41.0115, longitude: 28.9833, order: 2),
            Location(name: "Grand Bazaar", latitude: 41.0108, longitude: 28.9680, order: 3),
            Location(name: "Spice Bazaar", latitude: 41.0165, longitude: 28.9707, order: 4),
            Location(name: "Basilica Cistern", latitude: 41.0084, longitude: 28.9779, order: 5),
            Location(name: "Suleymaniye Mosque", latitude: 41.0163, longitude: 28.9638, order: 6)
        ]

        locations.forEach { location in
            location.list = list
            list.locations.append(location)
        }

        context.insert(list)
        return list
    }
}

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
