import Foundation
import MapKit
import SwiftData

/// Service for handling route optimization and related operations
enum RouteOptimizationService {
    // MARK: - Types

    /// Represents possible errors that can occur during route optimization
    enum OptimizationError: LocalizedError {
        case invalidLocations
        case optimizationFailed
        case networkError
        case invalidRouteData

        var errorDescription: String? {
            switch self {
            case .invalidLocations:
                return "Invalid or insufficient locations for optimization"
            case .optimizationFailed:
                return "Failed to optimize route"
            case .networkError:
                return "Network error occurred during optimization"
            case .invalidRouteData:
                return "Invalid route data received"
            }
        }
    }

    /// Represents the result of a route optimization
    struct RouteResult {
        /// The locations in optimized order
        let optimizedLocations: [Location]
        /// The coordinates forming the optimized route
        let routeCoordinates: [CLLocationCoordinate2D]
        /// Statistics about the optimized route
        let statistics: RouteService.RouteStatistics

        /// Formatted description of the route statistics
        var formattedStatistics: String {
            """
            Total Distance: \(String(format: "%.1f", statistics.totalDistance / 1000)) km
            Estimated Duration: \(String(format: "%.1f", statistics.estimatedDuration / 60)) minutes
            Number of Turns: \(statistics.numberOfTurns)
            Average Segment: \(String(format: "%.1f", statistics.averageSegmentLength / 1000)) km
            """
        }
    }

    // MARK: - Public Methods

    /// Optimizes the route for the given locations
    /// - Parameters:
    ///   - locations: Array of locations to optimize
    ///   - completion: Completion handler with the result
    static func optimizeRoute(
        for locations: [Location],
        completion: @escaping (Result<RouteResult, Error>) -> Void
    ) {
        // Validate input
        guard validateLocations(locations) else {
            Logger.error("Invalid locations for optimization")
            completion(.failure(OptimizationError.invalidLocations))
            return
        }

        // Check network connectivity
        guard NetworkConnectivityService.shared.checkConnectivity() else {
            Logger.error("No network connectivity")
            completion(.failure(OptimizationError.networkError))
            return
        }

        Logger.info("Original order: \(formatLocationOrder(locations))")

        // Perform optimization
        RouteService.fetchOptimizedRoute(locations: locations) { reorderedLocations, routeCoordinates, statistics in
            if let reorderedLocations = reorderedLocations,
               let routeCoordinates = routeCoordinates,
               let statistics = statistics {

                // Validate optimization result
                guard validateOptimizationResult(
                    original: locations,
                    optimized: reorderedLocations,
                    coordinates: routeCoordinates
                ) else {
                    Logger.error("Invalid optimization result")
                    completion(.failure(OptimizationError.invalidRouteData))
                    return
                }

                Logger.info("Reordered locations: \(formatLocationOrder(reorderedLocations))")
                logRouteStatistics(statistics)

                let result = RouteResult(
                    optimizedLocations: reorderedLocations,
                    routeCoordinates: routeCoordinates,
                    statistics: statistics
                )
                completion(.success(result))
            } else {
                Logger.error("Route optimization failed")
                completion(.failure(OptimizationError.optimizationFailed))
            }
        }
    }

    /// Updates the order of locations in a list after optimization
    /// - Parameters:
    ///   - list: The list containing the locations
    ///   - optimizedLocations: The locations in their optimized order
    ///   - context: The SwiftData model context
    /// - Throws: LocationListError if the update fails
    static func updateLocationOrders(
        in list: LocationList,
        with optimizedLocations: [Location],
        context: ModelContext
    ) throws {
        guard validateLocations(optimizedLocations) else {
            Logger.error("Invalid optimized locations")
            throw OptimizationError.invalidLocations
        }

        try LocationListService.updateLocationOrders(
            in: list,
            with: optimizedLocations,
            context: context
        )
    }

    // MARK: - Private Methods

    /// Validates the location array for optimization
    private static func validateLocations(_ locations: [Location]) -> Bool {
        // Check minimum requirements
        guard locations.count >= LocationList.minLocations else {
            return false
        }

        // Validate coordinates
        return locations.allSatisfy { location in
            LocationCoordinateService.isValidCoordinate(location.coordinate)
        }
    }

    /// Validates the optimization result
    private static func validateOptimizationResult(
        original: [Location],
        optimized: [Location],
        coordinates: [CLLocationCoordinate2D]
    ) -> Bool {
        // Check counts match
        guard original.count == optimized.count,
              !coordinates.isEmpty else {
            return false
        }

        // Verify all original locations are present in optimized list
        let originalSet = Set(original.map { $0.coordinateHash })
        let optimizedSet = Set(optimized.map { $0.coordinateHash })

        return originalSet == optimizedSet
    }

    /// Formats location order for logging
    private static func formatLocationOrder(_ locations: [Location]) -> String {
        locations.map { $0.name }.joined(separator: " → ")
    }

    /// Logs route statistics
    private static func logRouteStatistics(_ statistics: RouteService.RouteStatistics) {
        Logger.info("Route statistics:")
        Logger.info("- Total distance: \(String(format: "%.1f", statistics.totalDistance / 1000)) km")
        Logger.info("- Estimated duration: \(String(format: "%.1f", statistics.estimatedDuration / 60)) minutes")
        Logger.info("- Number of turns: \(statistics.numberOfTurns)")
        Logger.info("- Average segment: \(String(format: "%.1f", statistics.averageSegmentLength / 1000)) km")
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

// MARK: - Location Extensions

private extension Location {
    /// Generates a unique hash for the location's coordinates
    var coordinateHash: String {
        String(format: "%.6f,%.6f", latitude, longitude)
    }
}
