import Foundation
import MapKit

/// Service for handling location coordinate calculations and region management
enum LocationCoordinateService {
    // MARK: - Constants

    /// Default span multiplier to add padding around the region
    private static let defaultSpanMultiplier: Double = 1.3

    /// Default span for single location or user location
    private static let defaultLocationSpan = MKCoordinateSpan(
        latitudeDelta: 0.02,
        longitudeDelta: 0.02
    )

    /// Default region centered on Ankara
    static let ankaraRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK: - Public Methods

    /// Calculates a map region that encompasses all provided locations
    /// - Parameters:
    ///   - locations: Array of locations to include in the region
    ///   - userLocation: Optional user location to center the map on
    ///   - spanMultiplier: Multiplier for the region span (default: 1.3)
    /// - Returns: An MKCoordinateRegion that includes all locations
    static func calculateRegion(
        for locations: [Location],
        userLocation: CLLocationCoordinate2D? = nil,
        spanMultiplier: Double = defaultSpanMultiplier
    ) -> MKCoordinateRegion {
        // If user location is provided, center on it with default span
        if let userLocation = userLocation {
            return MKCoordinateRegion(
                center: userLocation,
                span: defaultLocationSpan
            )
        }

        // Return default region if no locations provided
        guard !locations.isEmpty else {
            return ankaraRegion
        }

        // Filter out invalid coordinates
        let validCoordinates = locations
            .map(\.coordinate)
            .filter { isValidCoordinate($0) }

        guard !validCoordinates.isEmpty else {
            return ankaraRegion
        }

        // Calculate region bounds in a single pass
        let bounds = validCoordinates.reduce(into: CoordinateBounds()) { bounds, coordinate in
            bounds.add(coordinate)
        }

        let center = CLLocationCoordinate2D(
            latitude: bounds.centerLatitude,
            longitude: bounds.centerLongitude
        )

        let span = MKCoordinateSpan(
            latitudeDelta: bounds.latitudeDelta * spanMultiplier,
            longitudeDelta: bounds.longitudeDelta * spanMultiplier
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    /// Calculates the total distance of a path through the given locations
    /// - Parameter locations: Array of locations in order
    /// - Returns: Total distance in meters
    static func calculateTotalDistance(through locations: [Location]) -> CLLocationDistance {
        guard locations.count > 1 else { return 0 }

        var totalDistance: CLLocationDistance = 0
        for i in 0..<(locations.count - 1) {
            let from = locations[i].coordinate
            let to = locations[i + 1].coordinate
            totalDistance += from.distance(from: to)
        }

        return totalDistance
    }

    /// Checks if a coordinate is valid and within reasonable bounds
    /// - Parameter coordinate: The coordinate to validate
    /// - Returns: Boolean indicating if the coordinate is valid
    static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return false }

        // Check if coordinates are non-zero and within reasonable bounds
        let isValidLatitude = coordinate.latitude != 0 && abs(coordinate.latitude) <= 90
        let isValidLongitude = coordinate.longitude != 0 && abs(coordinate.longitude) <= 180

        return isValidLatitude && isValidLongitude
    }
}

// MARK: - Helper Types

private struct CoordinateBounds {
    var minLat: Double = .infinity
    var maxLat: Double = -.infinity
    var minLon: Double = .infinity
    var maxLon: Double = -.infinity

    var centerLatitude: Double {
        (minLat + maxLat) / 2
    }

    var centerLongitude: Double {
        (minLon + maxLon) / 2
    }

    var latitudeDelta: Double {
        maxLat - minLat
    }

    var longitudeDelta: Double {
        maxLon - minLon
    }

    mutating func add(_ coordinate: CLLocationCoordinate2D) {
        minLat = min(minLat, coordinate.latitude)
        maxLat = max(maxLat, coordinate.latitude)
        minLon = min(minLon, coordinate.longitude)
        maxLon = max(maxLon, coordinate.longitude)
    }
}
