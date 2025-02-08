import Foundation
import MapKit

actor LocationSearchService {
    static func searchLocations(
        query: String,
        userLocation: CLLocationCoordinate2D? = nil,
        listLocations: [Location] = []
    ) async throws -> [MKMapItem] {
        guard !query.isEmpty else {
            return []
        }

        guard NetworkConnectivityService.shared.checkConnectivity() else {
            throw NetworkError.noInternetConnection
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        // Set the search region based on context
        if let userLocation = userLocation {
            // If we have user location, search around it with a reasonable radius
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 5000, // 5km radius
                longitudinalMeters: 5000
            )
            request.region = region
            print("🔍 Searching around user location: \(userLocation.latitude), \(userLocation.longitude)")
        } else if !listLocations.isEmpty {
            // If we have list locations, search in a region that encompasses them
            let region = LocationCoordinateService.calculateRegion(for: listLocations)
            // Expand the region slightly to include nearby results
            let expandedRegion = MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(
                    latitudeDelta: region.span.latitudeDelta * 1.5,
                    longitudeDelta: region.span.longitudeDelta * 1.5
                )
            )
            request.region = expandedRegion
            print("🔍 Searching around list locations")
        } else {
            // Fallback to default region
            request.region = LocationCoordinateService.ankaraRegion
            print("🔍 Searching in default region (Ankara)")
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("❌ Location search failed:", error.localizedDescription)
            throw NetworkError.locationSearchFailed
        }
    }
}
