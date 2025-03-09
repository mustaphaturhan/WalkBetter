import Foundation
import MapKit

/// A service that handles route optimization and calculation between multiple locations.
/// Uses a combination of straight-line distance calculation and MapKit's walking directions
/// to create optimized walking routes with caching for performance.
actor RouteService {
    // MARK: - Constants

    private static let queue = DispatchQueue(label: "com.walkbetter.routeservice", qos: .userInitiated)
    private static let requestDelay: TimeInterval = 0.2 // Reduced to 200ms
    private static let maxRetries = 3
    private static let maxConcurrentRequests = 3
    private static let cacheTimeout: TimeInterval = 300 // 5 minutes cache timeout

    // Default walking speed in meters per second (5 km/h)
    private static let defaultWalkingSpeed: Double = 1.4

    // MARK: - Error Types

    /// Errors specific to route calculation
    enum RouteError: Error, LocalizedError {
        case invalidLocations
        case insufficientLocations
        case optimizationFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidLocations:
                return "One or more locations contain invalid coordinates."
            case .insufficientLocations:
                return "At least two locations are required to create a route."
            case .optimizationFailed(let reason):
                return "Route optimization failed: \(reason)"
            }
        }
    }

    // MARK: - Cache Structures

    /// Cache structure to store previously calculated complete routes
    private static var cache: [String: (
        locations: [Location],
        optimizedLocations: [Location],
        routeCoordinates: [CLLocationCoordinate2D],
        timestamp: Date,
        statistics: RouteStatistics
    )] = [:]

    /// Cache structure for partial routes between two points
    private static var partialCache: [String: (
        distance: Double,
        coordinates: [CLLocationCoordinate2D],
        timestamp: Date
    )] = [:]

    // MARK: - Data Structures

    /// Statistics about a calculated route
    struct RouteStatistics: Equatable {
        let totalDistance: Double
        let estimatedDuration: TimeInterval
        let elevationGain: Double
        let numberOfTurns: Int
        let averageSegmentLength: Double

        /// Configuration for route calculation
        struct Configuration {
            /// Walking speed in meters per second
            var walkingSpeed: Double = RouteService.defaultWalkingSpeed
            /// Whether to prioritize fewer turns over shorter distance
            var prioritizeFewerTurns: Bool = false
            /// Maximum number of optimization iterations
            var maxOptimizationIterations: Int = 100

            static let `default` = Configuration()
        }

        static let zero = RouteStatistics(
            totalDistance: 0,
            estimatedDuration: 0,
            elevationGain: 0,
            numberOfTurns: 0,
            averageSegmentLength: 0
        )
    }

    // MARK: - Cache Key Generation

    private static func cacheKey(for locations: [Location]) -> String {
        // Sort coordinates to ensure consistent cache key regardless of order
        locations
            .map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }
            .sorted()
            .joined(separator: "|")
    }

    private static func partialCacheKey(from: Location, to: Location) -> String {
        let coords = [
            "\(from.coordinate.latitude),\(from.coordinate.longitude)",
            "\(to.coordinate.latitude),\(to.coordinate.longitude)"
        ].sorted()
        return coords.joined(separator: "|")
    }

    // MARK: - Public Methods

    /// Fetches an optimized walking route between multiple locations.
    /// - Parameters:
    ///   - locations: Array of locations to visit
    ///   - configuration: Optional configuration for route optimization
    ///   - completion: Callback with optimized locations, route coordinates, and statistics
    static func fetchOptimizedRoute(
        locations: [Location],
        configuration: RouteStatistics.Configuration = .default,
        completion: @escaping (Result<(optimizedLocations: [Location], routeCoordinates: [CLLocationCoordinate2D], statistics: RouteStatistics), Error>) -> Void
    ) {
        // Check if we have a valid cached route for these exact locations
        let key = cacheKey(for: locations)
        print("🔑 Cache key:", key)
        print("📍 Looking for cache with locations:", locations.map { $0.name }.joined(separator: ", "))

        // Check cache first
        if let cached = cache[key] {
            print("✨ Found cache entry for key")
            let isCacheValid = Date().timeIntervalSince(cached.timestamp) < cacheTimeout &&
                             cached.locations.count == locations.count

            // Create sets of coordinate strings for order-independent comparison
            let cachedCoords = Set(cached.locations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })
            let currentCoords = Set(locations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })

            if isCacheValid && cachedCoords == currentCoords {
                print("✅ Using cached route")
                completion(.success((cached.optimizedLocations, cached.routeCoordinates, cached.statistics)))
                return
            } else {
                if !isCacheValid {
                    print("⏰ Cache expired or location count mismatch")
                } else {
                    print("❌ Location coordinates don't match")
                }
            }
        } else {
            print("❌ No cache entry found for key")
        }

        // Proceed with route calculation if cache is invalid or missing
        guard locations.count > 1 else {
            print("❌ Not enough locations for route")
            completion(.failure(RouteError.insufficientLocations))
            return
        }

        // Validate locations
        guard validateLocations(locations) else {
            print("❌ Invalid locations detected")
            completion(.failure(RouteError.invalidLocations))
            return
        }

        // Check network connectivity
        guard NetworkConnectivityService.shared.checkConnectivity() else {
            print("❌ No internet connection available for route optimization")
            completion(.failure(NetworkError.noInternetConnection))
            return
        }

        print("🔄 Calculating new route...")

        // Main async task
        Task {
            do {
                // Build distance matrix using straight-line distances first
                let straightLineMatrix = buildStraightLineMatrix(for: locations)

                // Get initial optimized route using straight-line distances
                let initialOrder = optimizeRoute(
                    durations: straightLineMatrix,
                    prioritizeFewerTurns: configuration.prioritizeFewerTurns,
                    maxIterations: configuration.maxOptimizationIterations
                )
                let initialOptimizedLocations = initialOrder.map { locations[$0] }

                // Get actual walking distances only for the optimized path
                var walkingDistances: [Double] = []
                var pathCoordinates: [[CLLocationCoordinate2D]] = []
                var totalElevationGain: Double = 0
                var numberOfTurns: Int = 0

                // Create task groups for concurrent fetching
                try await withThrowingTaskGroup(of: (Int, Double, [CLLocationCoordinate2D], Double, Int).self) { group in
                    for i in 0..<(initialOptimizedLocations.count - 1) {
                        group.addTask {
                            // Check partial cache first
                            if let cached = try await getPartialCachedRoute(
                                from: initialOptimizedLocations[i],
                                to: initialOptimizedLocations[i + 1]
                            ) {
                                print("✅ Using cached partial route for segment \(i)")
                                // Estimate turns from coordinates
                                let turns = estimateTurns(in: cached.coordinates)
                                return (i, cached.distance, cached.coordinates, 0.0, turns)
                            }

                            print("🔄 Calculating route for segment \(i)")
                            // Fetch new route with retries
                            var attempts = 0
                            while attempts < maxRetries {
                                do {
                                    let (distance, coordinates, elevationGain) = try await getWalkingPathAndDistance(
                                        from: initialOptimizedLocations[i],
                                        to: initialOptimizedLocations[i + 1]
                                    )

                                    // Estimate turns from coordinates
                                    let turns = estimateTurns(in: coordinates)

                                    // Cache the partial route
                                    await cachePartialRoute(
                                        from: initialOptimizedLocations[i],
                                        to: initialOptimizedLocations[i + 1],
                                        distance: distance,
                                        coordinates: coordinates
                                    )

                                    return (i, distance, coordinates, elevationGain, turns)
                                } catch {
                                    attempts += 1
                                    if attempts == maxRetries {
                                        print("❌ All retries failed for segment \(i): \(error.localizedDescription)")
                                        // Fallback to straight-line
                                        let distance = initialOptimizedLocations[i].coordinate
                                            .distance(from: initialOptimizedLocations[i + 1].coordinate)
                                        return (i, distance, [
                                            initialOptimizedLocations[i].coordinate,
                                            initialOptimizedLocations[i + 1].coordinate
                                        ], 0.0, 0)
                                    }
                                    try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
                                }
                            }
                            fatalError("Should not reach here")
                        }
                    }

                    // Process results in order
                    var orderedResults = [(Int, Double, [CLLocationCoordinate2D], Double, Int)]()
                    for try await result in group {
                        orderedResults.append(result)
                    }

                    // Sort and process results
                    orderedResults.sort { $0.0 < $1.0 }
                    for (_, distance, coordinates, elevation, turns) in orderedResults {
                        walkingDistances.append(distance)
                        pathCoordinates.append(coordinates)
                        totalElevationGain += elevation
                        numberOfTurns += turns
                    }
                }

                // Combine all path coordinates
                let routeCoordinates = pathCoordinates.flatMap { $0 }

                // Calculate route statistics
                let totalDistance = walkingDistances.reduce(0, +)
                let statistics = RouteStatistics(
                    totalDistance: totalDistance,
                    estimatedDuration: calculateEstimatedDuration(
                        distances: walkingDistances,
                        walkingSpeed: configuration.walkingSpeed
                    ),
                    elevationGain: totalElevationGain,
                    numberOfTurns: numberOfTurns,
                    averageSegmentLength: totalDistance > 0 && !walkingDistances.isEmpty ?
                        totalDistance / Double(walkingDistances.count) : 0
                )

                print("✅ Route calculation completed")
                print("📊 Total distance: \(String(format: "%.1f", statistics.totalDistance / 1000)) km")
                print("⏱️ Estimated duration: \(String(format: "%.1f", statistics.estimatedDuration / 60)) minutes")
                print("🏔️ Elevation gain: \(String(format: "%.1f", statistics.elevationGain)) meters")
                print("↩️ Number of turns: \(statistics.numberOfTurns)")

                // Cache the results
                cache[key] = (
                    locations: locations,
                    optimizedLocations: initialOptimizedLocations,
                    routeCoordinates: routeCoordinates,
                    timestamp: Date(),
                    statistics: statistics
                )

                // Clean old cache entries
                cleanCache()

                // Return result on main queue
                await MainActor.run {
                    completion(.success((initialOptimizedLocations, routeCoordinates, statistics)))
                }
            } catch {
                await MainActor.run {
                    print("❌ Route optimization error:", error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Checks if a route for the given locations exists in the cache
    /// - Parameter locations: The locations to check
    /// - Returns: True if a valid cached route exists
    static func hasCachedRoute(for locations: [Location]) -> Bool {
        let key = cacheKey(for: locations)
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheTimeout,
              cached.locations.count == locations.count else {
            return false
        }

        let cachedCoords = Set(cached.locations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })
        let currentCoords = Set(locations.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" })
        return cachedCoords == currentCoords
    }

    /// Clears all cached routes
    static func clearCache() {
        cache.removeAll()
        partialCache.removeAll()
    }

    // MARK: - Private Helper Methods

    /// Validates that all locations have valid coordinates
    private static func validateLocations(_ locations: [Location]) -> Bool {
        // Check for invalid coordinates
        for location in locations {
            let coord = location.coordinate
            guard CLLocationCoordinate2DIsValid(coord),
                  coord.latitude != 0 || coord.longitude != 0 else {
                return false
            }
        }
        return true
    }

    /// Calculates the estimated duration based on distance and walking speed
    private static func calculateEstimatedDuration(distances: [Double], walkingSpeed: Double = defaultWalkingSpeed) -> TimeInterval {
        // Add time for turns and elevation changes
        return distances.reduce(0) { $0 + $1 / walkingSpeed }
    }

    /// Estimates the number of significant turns in a path
    private static func estimateTurns(in coordinates: [CLLocationCoordinate2D]) -> Int {
        guard coordinates.count >= 3 else { return 0 }

        var turns = 0
        let significantAngleThreshold = 20.0 // degrees

        for i in 1..<coordinates.count-1 {
            let prev = coordinates[i-1]
            let current = coordinates[i]
            let next = coordinates[i+1]

            // Calculate bearings
            let bearing1 = calculateBearing(from: prev, to: current)
            let bearing2 = calculateBearing(from: current, to: next)

            // Calculate angle difference
            var angleDiff = abs(bearing2 - bearing1)
            if angleDiff > 180 {
                angleDiff = 360 - angleDiff
            }

            // Count as turn if angle is significant
            if angleDiff > significantAngleThreshold {
                turns += 1
            }
        }

        return turns
    }

    /// Calculates the bearing between two coordinates in degrees
    private static func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Retrieves a cached partial route between two locations
    private static func getPartialCachedRoute(from: Location, to: Location) async throws -> (distance: Double, coordinates: [CLLocationCoordinate2D])? {
        let key = partialCacheKey(from: from, to: to)
        guard let cached = partialCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheTimeout else {
            return nil
        }
        return (cached.distance, cached.coordinates)
    }

    /// Caches a partial route between two locations
    private static func cachePartialRoute(from: Location, to: Location, distance: Double, coordinates: [CLLocationCoordinate2D]) async {
        let key = partialCacheKey(from: from, to: to)
        partialCache[key] = (
            distance: distance,
            coordinates: coordinates,
            timestamp: Date()
        )
        cleanPartialCache()
    }

    /// Removes expired entries from the partial route cache
    private static func cleanPartialCache() {
        let now = Date()
        partialCache = partialCache.filter {
            now.timeIntervalSince($0.value.timestamp) < cacheTimeout
        }
    }

    /// Builds a distance matrix using straight-line distances
    private static func buildStraightLineMatrix(for locations: [Location]) -> [[Double]] {
        print("🏗️ Building straight-line distance matrix for \(locations.count) locations")
        var matrix = Array(repeating: Array(repeating: Double.infinity, count: locations.count), count: locations.count)

        for i in 0..<locations.count {
            for j in 0..<locations.count where i != j {
                matrix[i][j] = locations[i].coordinate.distance(from: locations[j].coordinate)
            }
        }

        return matrix
    }

    /// Gets the walking path and distance between two locations using MapKit
    private static func getWalkingPathAndDistance(from: Location, to: Location) async throws -> (Double, [CLLocationCoordinate2D], Double) {
        guard NetworkConnectivityService.shared.checkConnectivity() else {
            throw NetworkError.noInternetConnection
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.coordinate))
            request.transportType = .walking

            MKDirections(request: request).calculate { response, error in
                if let error = error {
                    print("❌ Walking path error:", error.localizedDescription)
                    continuation.resume(throwing: NetworkError.routeOptimizationFailed)
                    return
                }

                guard let route = response?.routes.first else {
                    let error = NetworkError.routeOptimizationFailed
                    continuation.resume(throwing: error)
                    return
                }

                print("✅ Found path: \(from.name) -> \(to.name) (\(route.polyline.pointCount) points)")

                // Calculate estimated elevation gain (simplified)
                let elevationGain = estimateElevationGain(for: route)

                continuation.resume(returning: (route.distance, route.polyline.coordinates, elevationGain))
            }
        }
    }

    /// Estimates elevation gain from a route (simplified implementation)
    private static func estimateElevationGain(for route: MKRoute) -> Double {
        // In a real implementation, you would use elevation data from the route
        // This is a simplified placeholder that estimates based on distance
        // A more accurate implementation would use actual elevation data
        return route.distance * 0.01 // Rough estimate: 10m gain per 1km
    }

    /// Removes expired entries from the route cache
    private static func cleanCache() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) < cacheTimeout }
    }

    // MARK: - Route Optimization Algorithms

    /// Optimizes a route using the 2-opt algorithm
    private static func optimizeRoute(
        durations: [[Double]],
        prioritizeFewerTurns: Bool = false,
        maxIterations: Int = 100
    ) -> [Int] {
        let n = durations.count

        // Initial route using Nearest Neighbor
        var route = nearestNeighborRoute(durations: durations)
        var bestDistance = calculateTotalDistance(route: route, durations: durations)
        var improved = true
        var iterations = 0

        // 2-opt improvement
        while improved && iterations < maxIterations {
            improved = false
            iterations += 1

            for i in 0..<n-2 {
                for j in i+2..<n {
                    let newDistance = calculateSwapDistance(route: route, i: i, j: j, durations: durations)

                    // If prioritizing fewer turns, we might accept a slightly longer route
                    let shouldSwap = prioritizeFewerTurns
                        ? newDistance < bestDistance * 1.05 // Allow up to 5% longer routes for fewer turns
                        : newDistance < bestDistance

                    if shouldSwap {
                        route = twoOptSwap(route: route, i: i, j: j)
                        bestDistance = newDistance
                        improved = true
                        break
                    }
                }
                if improved { break }
            }
        }

        return route
    }

    /// Creates an initial route using the Nearest Neighbor algorithm
    private static func nearestNeighborRoute(durations: [[Double]]) -> [Int] {
        let n = durations.count
        var unvisited = Set(0..<n)
        var route: [Int] = []
        var current = 0 // Start with the first location

        route.append(current)
        unvisited.remove(current)

        while !unvisited.isEmpty {
            var bestNext = -1
            var bestDistance = Double.infinity

            for next in unvisited {
                let distance = durations[current][next]
                if distance < bestDistance {
                    bestDistance = distance
                    bestNext = next
                }
            }

            if bestNext != -1 {
                current = bestNext
                route.append(current)
                unvisited.remove(current)
            }
        }

        return route
    }

    /// Calculates the total distance of a route
    private static func calculateTotalDistance(route: [Int], durations: [[Double]]) -> Double {
        var totalDistance = 0.0
        for i in 0..<route.count-1 {
            totalDistance += durations[route[i]][route[i+1]]
        }
        return totalDistance
    }

    /// Calculates the distance if we swap two edges in a route
    private static func calculateSwapDistance(route: [Int], i: Int, j: Int, durations: [[Double]]) -> Double {
        let newRoute = twoOptSwap(route: route, i: i, j: j)
        return calculateTotalDistance(route: newRoute, durations: durations)
    }

    /// Performs a 2-opt swap on a route
    private static func twoOptSwap(route: [Int], i: Int, j: Int) -> [Int] {
        var newRoute = route
        var k = i + 1
        var l = j
        while k < l {
            newRoute.swapAt(k, l)
            k += 1
            l -= 1
        }
        return newRoute
    }
}

// MARK: - Extensions

/// Extension to extract coordinates from MKPolyline
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

/// Extension to calculate distance between coordinates
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}

