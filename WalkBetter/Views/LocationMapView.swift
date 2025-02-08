import SwiftUI
import MapKit
import SwiftData

struct LocationMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var list: LocationList
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .automatic
    @State private var route: [CLLocationCoordinate2D] = []
    @Environment(\.networkService) private var networkService
    @State private var totalDistance: CLLocationDistance = 0
    @State private var hasAttemptedRouteLoad = false

    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(Array(list.sortedLocations.enumerated()), id: \.element.id) { index, location in
                    Annotation(
                        location.name,
                        coordinate: location.coordinate
                    ) {
                        LocationMapMarker(
                            isFirst: location == list.sortedLocations.first,
                            isLast: location == list.sortedLocations.last,
                            index: location == list.sortedLocations.first || location == list.sortedLocations.last ? nil : index + 1
                        )
                    }
                }

                if !route.isEmpty {
                    MapPolyline(coordinates: route)
                        .stroke(
                            .linearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 4,
                                dash: [8, 4]
                            )
                        )
                }

                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    if !networkService.isConnected {
                        NetworkStatusView()
                    } else {
                        // Route Legend
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Route Information")
                                .font(.headline)

                            HStack(spacing: 16) {
                                // Start
                                HStack(spacing: 8) {
                                    Image(systemName: "flag.fill")
                                        .foregroundStyle(.green)
                                    Text("Start")
                                        .font(.subheadline)
                                }

                                // Stops
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 16, height: 16)
                                        .overlay {
                                            Text("1")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.white)
                                        }
                                    Text("Stops")
                                        .font(.subheadline)
                                }

                                // End
                                HStack(spacing: 8) {
                                    Image(systemName: "flag.checkered")
                                        .foregroundStyle(.blue)
                                    Text("End")
                                        .font(.subheadline)
                                }
                            }

                            if totalDistance > 0 {
                                HStack {
                                    Image(systemName: "figure.walk")
                                    Text(String(format: "Total Distance: %.1f km", totalDistance / 1000))
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Map View")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            print("📍 Map View appeared")
            centerOnLocations()
            loadRouteIfNeeded()
        }
        .onChange(of: networkService.isConnected) { _, isConnected in
            print("🌐 Network state changed: \(isConnected ? "Connected" : "Disconnected")")
            if isConnected {
                loadRouteIfNeeded()
            }
        }
    }

    private func centerOnLocations() {
        withAnimation {
            position = .region(
                LocationCoordinateService.calculateRegion(
                    for: list.sortedLocations,
                    userLocation: locationManager.userLocation
                )
            )
        }
    }

    private func loadRouteIfNeeded() {
        guard networkService.isConnected else {
            print("❌ No network connection available")
            return
        }

        let sortedLocations = list.sortedLocations
        guard sortedLocations.count >= LocationList.minLocations else {
            print("❌ Not enough locations for route calculation")
            return
        }

        print("🗺️ Loading route for locations:", sortedLocations.map { "\($0.name) (order: \($0.order))" }.joined(separator: ", "))

        // Check if we have a cached route
        if RouteService.hasCachedRoute(for: sortedLocations) {
            print("✨ Found cached route")
        } else {
            print("🔄 No cached route found, calculating new route")
        }

        RouteService.fetchOptimizedRoute(locations: sortedLocations) { optimizedLocations, routeCoordinates, statistics in
            DispatchQueue.main.async {
                if let routeCoordinates = routeCoordinates {
                    print("✅ Route loaded with \(routeCoordinates.count) coordinates")
                    withAnimation {
                        self.route = routeCoordinates
                        if let statistics = statistics {
                            self.totalDistance = statistics.totalDistance
                        }
                    }
                } else {
                    print("❌ Failed to load route coordinates")
                }
            }
        }
    }

    private func calculateTotalDistance(from coordinates: [CLLocationCoordinate2D]) {
        var distance: CLLocationDistance = 0
        for i in 0..<coordinates.count - 1 {
            let from = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let to = CLLocation(latitude: coordinates[i + 1].latitude, longitude: coordinates[i + 1].longitude)
            distance += from.distance(from: to)
        }
        self.totalDistance = distance
    }
}

#Preview("Brussels Tour - Online") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createBrusselsList(in: container.mainContext)
        return NavigationStack {
            LocationMapView(list: list)
        }
    }
}

#Preview("Brussels Tour - Offline") {
    PreviewHelperService.previewWithContainer(isConnected: false) { container in
        let list = PreviewHelperService.createBrusselsList(in: container.mainContext)
        return NavigationStack {
            LocationMapView(list: list)
        }
    }
}

#Preview("Paris Highlights - Online") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createParisList(in: container.mainContext)
        return NavigationStack {
            LocationMapView(list: list)
        }
    }
}

#Preview("Paris Highlights - Offline") {
    PreviewHelperService.previewWithContainer(isConnected: false) { container in
        let list = PreviewHelperService.createParisList(in: container.mainContext)
        return NavigationStack {
            LocationMapView(list: list)
        }
    }
}

