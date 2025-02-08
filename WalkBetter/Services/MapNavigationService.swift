import Foundation
import MapKit
import UIKit

/// Service for handling external map navigation integrations
enum MapNavigationService {
    // MARK: - Types

    /// Represents possible errors that can occur during map navigation
    enum NavigationError: LocalizedError {
        case emptyLocationList
        case invalidURL
        case invalidLocation

        var errorDescription: String? {
            switch self {
            case .emptyLocationList:
                return "Cannot open maps: location list is empty"
            case .invalidURL:
                return "Failed to create valid map URL"
            case .invalidLocation:
                return "Invalid location data"
            }
        }
    }

    /// Supported navigation modes
    enum NavigationMode {
        case walking
        case driving

        var appleMapsValue: String {
            switch self {
            case .walking: return "w"
            case .driving: return "d"
            }
        }

        var googleMapsValue: String {
            switch self {
            case .walking: return "walking"
            case .driving: return "driving"
            }
        }
    }

    // MARK: - Public Methods

    /// Opens the route in Apple Maps
    /// - Parameters:
    ///   - locations: Array of locations to include in the route
    ///   - mode: Navigation mode (walking or driving)
    /// - Throws: NavigationError if the operation fails
    static func openInAppleMaps(
        locations: [Location],
        mode: NavigationMode = .driving
    ) throws {
        try validateLocations(locations)
        Logger.info("Opening Apple Maps with \(locations.count) locations")
        Logger.info("Location order: \(locations.map { $0.name }.joined(separator: " → "))")

        // For two locations, use MKMapItem approach for better integration
        if locations.count == 2 {
            try openDirectRouteInAppleMaps(locations: locations, mode: mode)
            return
        }

        // For more locations, use URL scheme
        try openMultiStopRouteInAppleMaps(locations: locations, mode: mode)
    }

    /// Opens the route in Google Maps
    /// - Parameters:
    ///   - locations: Array of locations to include in the route
    ///   - mode: Navigation mode (walking or driving)
    /// - Throws: NavigationError if the operation fails
    static func openInGoogleMaps(
        locations: [Location],
        mode: NavigationMode = .walking
    ) throws {
        try validateLocations(locations)
        Logger.info("Opening Google Maps with \(locations.count) locations")
        Logger.info("Location order: \(locations.map { $0.name }.joined(separator: " → "))")

        let origin = formatCoordinate(locations[0].coordinate)
        let destination = formatCoordinate(locations.last!.coordinate)

        Logger.info("Start: \(locations[0].name)")
        Logger.info("Final destination: \(locations.last?.name ?? "Unknown")")

        // Get waypoints (excluding first and last locations)
        let waypoints = locations.dropFirst().dropLast()
            .map { formatCoordinate($0.coordinate) }
            .joined(separator: "|")

        if !waypoints.isEmpty {
            Logger.info("Waypoints: \(locations.dropFirst().dropLast().map { $0.name }.joined(separator: " → "))")
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.google.com"
        urlComponents.path = "/maps/dir/"
        urlComponents.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "travelmode", value: mode.googleMapsValue)
        ]

        if !waypoints.isEmpty {
            urlComponents.queryItems?.append(URLQueryItem(name: "waypoints", value: waypoints))
        }

        guard let url = urlComponents.url else {
            Logger.error("Failed to create Google Maps URL")
            throw NavigationError.invalidURL
        }

        Logger.info("Generated URL: \(url.absoluteString)")
        UIApplication.shared.open(url)
        Logger.success("Opened Google Maps")
    }

    // MARK: - Private Methods

    /// Validates the location array
    private static func validateLocations(_ locations: [Location]) throws {
        guard !locations.isEmpty else {
            Logger.error("Empty location list")
            throw NavigationError.emptyLocationList
        }

        guard locations.allSatisfy({ LocationCoordinateService.isValidCoordinate($0.coordinate) }) else {
            Logger.error("Invalid location coordinates detected")
            throw NavigationError.invalidLocation
        }
    }

    /// Opens a direct route between two locations in Apple Maps
    private static func openDirectRouteInAppleMaps(
        locations: [Location],
        mode: NavigationMode
    ) throws {
        Logger.info("Opening direct route between 2 locations")
        let items = locations.map { location -> MKMapItem in
            let placemark = MKPlacemark(coordinate: location.coordinate)
            let item = MKMapItem(placemark: placemark)
            item.name = location.name
            return item
        }

        MKMapItem.openMaps(
            with: items,
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: mode == .walking ?
                    MKLaunchOptionsDirectionsModeWalking :
                    MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: NSNumber(value: false)
            ]
        )
        Logger.success("Opened Apple Maps with direct route")
    }

    /// Opens a multi-stop route in Apple Maps using URL scheme
    private static func openMultiStopRouteInAppleMaps(
        locations: [Location],
        mode: NavigationMode
    ) throws {
        Logger.info("Creating multi-stop route URL")
        var directionsString = "http://maps.apple.com/?saddr="

        // Add start address
        directionsString += formatCoordinate(locations[0].coordinate)

        // Add destination and intermediate stops
        for location in locations.dropFirst() {
            directionsString += "&daddr=\(formatCoordinate(location.coordinate))"
        }

        // Add transport mode
        directionsString += "&dirflg=\(mode.appleMapsValue)"

        guard let encodedString = directionsString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            Logger.error("Failed to create Apple Maps URL")
            throw NavigationError.invalidURL
        }

        Logger.info("Generated URL: \(url.absoluteString)")
        UIApplication.shared.open(url)
        Logger.success("Opened Apple Maps with multi-stop route")
    }

    /// Formats a coordinate for URL inclusion
    private static func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.6f,%.6f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Logging Utility

private enum Logger {
    static func success(_ message: String) {
        print("✅ \(message)")
    }

    static func error(_ message: String) {
        print("❌ \(message)")
    }

    static func warning(_ message: String) {
        print("⚠️ \(message)")
    }

    static func info(_ message: String) {
        print("📍 \(message)")
    }
}
