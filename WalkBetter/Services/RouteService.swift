import Foundation
import MapKit

actor RouteService {
    private static let queue = DispatchQueue(label: "com.walkbetter.routeservice", qos: .userInitiated)
    private static let requestDelay: TimeInterval = 0.2 // Reduced to 200ms
    private static let maxRetries = 3
    private static let maxConcurrentRequests = 3

    // Cache structure to store previously calculated routes
    private static var cache: [String: (
        locations: [Location],
        optimizedLocations: [Location],
        routeCoordinates: [CLLocationCoordinate2D],
        timestamp: Date,
        statistics: RouteStatistics
    )] = [:]

    // Cache structure for partial routes
    private static var partialCache: [String: (
        distance: Double,
        coordinates: [CLLocationCoordinate2D],
        timestamp: Date
    )] = [:]

    private static let cacheTimeout: TimeInterval = 300 // 5 minutes cache timeout

    // Route statistics structure
    struct RouteStatistics {
        let totalDistance: Double
        let estimatedDuration: TimeInterval
        let elevationGain: Double
        let numberOfTurns: Int
        let averageSegmentLength: Double

        static let zero = RouteStatistics(
            totalDistance: 0,
            estimatedDuration: 0,
            elevationGain: 0,
            numberOfTurns: 0,
            averageSegmentLength: 0
        )
    }

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

    static func fetchOptimizedRoute(
        locations: [Location],
        completion: @escaping ([Location]?, [CLLocationCoordinate2D]?, RouteStatistics?) -> Void
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
                completion(cached.optimizedLocations, cached.routeCoordinates, cached.statistics)
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
            completion(nil, nil, nil)
            return
        }

        // Validate locations
        guard validateLocations(locations) else {
            print("❌ Invalid locations detected")
            completion(nil, nil, nil)
            return
        }

        // Check network connectivity
        guard NetworkConnectivityService.shared.checkConnectivity() else {
            print("❌ No internet connection available for route optimization")
            completion(nil, nil, nil)
            return
        }

        print("🔄 Calculating new route...")

        // Main async task
        Task {
            do {
                // Build distance matrix using straight-line distances first
                let straightLineMatrix = buildStraightLineMatrix(for: locations)

                // Get initial optimized route using straight-line distances
                let initialOrder = optimizeRoute(durations: straightLineMatrix)
                let initialOptimizedLocations = initialOrder.map { locations[$0] }

                // Get actual walking distances only for the optimized path
                var walkingDistances: [Double] = []
                var pathCoordinates: [[CLLocationCoordinate2D]] = []
                let totalElevationGain: Double = 0
                var numberOfTurns: Int = 0

                // Create task groups for concurrent fetching
                try await withThrowingTaskGroup(of: (Int, Double, [CLLocationCoordinate2D]).self) { group in
                    for i in 0..<(initialOptimizedLocations.count - 1) {
                        group.addTask {
                            // Check partial cache first
                            if let cached = try await getPartialCachedRoute(
                                from: initialOptimizedLocations[i],
                                to: initialOptimizedLocations[i + 1]
                            ) {
                                print("✅ Using cached partial route for segment \(i)")
                                return (i, cached.distance, cached.coordinates)
                            }

                            print("🔄 Calculating route for segment \(i)")
                            // Fetch new route with retries
                            var attempts = 0
                            while attempts < maxRetries {
                                do {
                                    let (distance, coordinates) = try await getWalkingPathAndDistance(
                                        from: initialOptimizedLocations[i],
                                        to: initialOptimizedLocations[i + 1]
                                    )

                                    // Cache the partial route
                                    await cachePartialRoute(
                                        from: initialOptimizedLocations[i],
                                        to: initialOptimizedLocations[i + 1],
                                        distance: distance,
                                        coordinates: coordinates
                                    )

                                    return (i, distance, coordinates)
                                } catch {
                                    attempts += 1
                                    if attempts == maxRetries {
                                        print("❌ All retries failed for segment \(i)")
                                        // Fallback to straight-line
                                        let distance = initialOptimizedLocations[i].coordinate
                                            .distance(from: initialOptimizedLocations[i + 1].coordinate)
                                        return (i, distance, [
                                            initialOptimizedLocations[i].coordinate,
                                            initialOptimizedLocations[i + 1].coordinate
                                        ])
                                    }
                                    try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
                                }
                            }
                            fatalError("Should not reach here")
                        }
                    }

                    // Process results in order
                    var orderedResults = [(Int, Double, [CLLocationCoordinate2D])]()
                    for try await result in group {
                        orderedResults.append(result)
                    }

                    // Sort and process results
                    orderedResults.sort { $0.0 < $1.0 }
                    for (_, distance, coordinates) in orderedResults {
                        walkingDistances.append(distance)
                        pathCoordinates.append(coordinates)

                        // Calculate turns (simplified)
                        if coordinates.count >= 3 {
                            numberOfTurns += coordinates.count - 2
                        }
                    }
                }

                // Combine all path coordinates
                let routeCoordinates = pathCoordinates.flatMap { $0 }

                // Calculate route statistics
                let statistics = RouteStatistics(
                    totalDistance: walkingDistances.reduce(0, +),
                    estimatedDuration: calculateEstimatedDuration(distances: walkingDistances),
                    elevationGain: totalElevationGain,
                    numberOfTurns: numberOfTurns,
                    averageSegmentLength: walkingDistances.reduce(0, +) / Double(walkingDistances.count)
                )

                print("✅ Route calculation completed")
                print("📊 Total distance: \(String(format: "%.1f", statistics.totalDistance / 1000)) km")

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
                    completion(initialOptimizedLocations, routeCoordinates, statistics)
                }
            } catch {
                await MainActor.run {
                    print("❌ Route optimization error:", error.localizedDescription)
                    completion(nil, nil, nil)
                }
            }
        }
    }

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

    private static func calculateEstimatedDuration(distances: [Double]) -> TimeInterval {
        // Average walking speed: 5 km/h = 1.4 m/s
        let averageWalkingSpeed = 1.4
        return distances.reduce(0) { $0 + $1 / averageWalkingSpeed }
    }

    private static func getPartialCachedRoute(from: Location, to: Location) async throws -> (distance: Double, coordinates: [CLLocationCoordinate2D])? {
        let key = partialCacheKey(from: from, to: to)
        guard let cached = partialCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheTimeout else {
            return nil
        }
        return (cached.distance, cached.coordinates)
    }

    private static func cachePartialRoute(from: Location, to: Location, distance: Double, coordinates: [CLLocationCoordinate2D]) async {
        let key = partialCacheKey(from: from, to: to)
        partialCache[key] = (
            distance: distance,
            coordinates: coordinates,
            timestamp: Date()
        )
        cleanPartialCache()
    }

    private static func cleanPartialCache() {
        let now = Date()
        partialCache = partialCache.filter {
            now.timeIntervalSince($0.value.timestamp) < cacheTimeout
        }
    }

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

    private static func getWalkingPathAndDistance(from: Location, to: Location) async throws -> (Double, [CLLocationCoordinate2D]) {
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
                continuation.resume(returning: (route.distance, route.polyline.coordinates))
            }
        }
    }

    private static func cleanCache() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) < cacheTimeout }
    }

    static func clearCache() {
        cache.removeAll()
    }

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

    // 🔄 Optimize Route Using 2-opt Algorithm
    private static func optimizeRoute(durations: [[Double]]) -> [Int] {
        let n = durations.count

        // Initial route using Nearest Neighbor
        var route = nearestNeighborRoute(durations: durations)
        var bestDistance = calculateTotalDistance(route: route, durations: durations)
        var improved = true

        // 2-opt improvement
        while improved {
            improved = false
            for i in 0..<n-2 {
                for j in i+2..<n {
                    let newDistance = calculateSwapDistance(route: route, i: i, j: j, durations: durations)
                    if newDistance < bestDistance {
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

    // Initial route using Nearest Neighbor
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

    // Calculate total distance of a route
    private static func calculateTotalDistance(route: [Int], durations: [[Double]]) -> Double {
        var totalDistance = 0.0
        for i in 0..<route.count-1 {
            totalDistance += durations[route[i]][route[i+1]]
        }
        return totalDistance
    }

    // Calculate distance if we swap two edges
    private static func calculateSwapDistance(route: [Int], i: Int, j: Int, durations: [[Double]]) -> Double {
        let newRoute = twoOptSwap(route: route, i: i, j: j)
        return calculateTotalDistance(route: newRoute, durations: durations)
    }

    // Perform 2-opt swap
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

// 🔥 Extension to Extract Coordinates from MKPolyline
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

// 📏 Extension to Calculate Distance Between Coordinates
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
