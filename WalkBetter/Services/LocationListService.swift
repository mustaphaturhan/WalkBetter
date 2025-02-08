import Foundation
import SwiftData
import MapKit

/// Service for managing location lists and their associated locations
enum LocationListService {
    // MARK: - Types

    /// Represents possible errors that can occur during location list operations
    enum Error: LocalizedError {
        case listFull
        case invalidLocation
        case locationNotFound
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .listFull:
                return "Cannot add more locations to this list"
            case .invalidLocation:
                return "Invalid location data"
            case .locationNotFound:
                return "Location not found in the list"
            case .saveFailed:
                return "Failed to save changes"
            }
        }
    }

    // MARK: - Location Management

    /// Adds a new location to the specified list
    /// - Parameters:
    ///   - mapItem: The map item containing location information
    ///   - list: The list to add the location to
    ///   - order: Optional order for the location (defaults to end of list)
    ///   - context: The SwiftData model context
    /// - Throws: LocationListService.Error if the operation fails
    static func addLocation(
        from mapItem: MKMapItem,
        to list: LocationList,
        at order: Int? = nil,
        context: ModelContext
    ) throws {
        // Validate inputs
        guard list.canAddMoreLocations else {
            throw Error.listFull
        }

        guard let name = mapItem.name,
              LocationCoordinateService.isValidCoordinate(mapItem.placemark.coordinate) else {
            throw Error.invalidLocation
        }

        // Create and configure location
        let location = Location(
            name: name,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            order: order ?? list.locations.count
        )

        // Update list
        location.list = list
        list.locations.append(location)
        list.isOptimized = false

        // Clear route cache
        RouteService.clearCache()

        do {
            try context.save()
            Logger.success("Added location: \(location.name)")
        } catch {
            Logger.error("Failed to save location: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    /// Adds a location as the starting point of the route
    /// - Parameters:
    ///   - mapItem: The map item containing location information
    ///   - list: The list to add the location to
    ///   - context: The SwiftData model context
    /// - Throws: LocationListService.Error if the operation fails
    static func addStartingPoint(
        from mapItem: MKMapItem,
        to list: LocationList,
        context: ModelContext
    ) throws {
        guard list.canAddMoreLocations else {
            throw Error.listFull
        }

        // Increment order of existing locations
        for location in list.locations {
            location.order += 1
        }

        try addLocation(from: mapItem, to: list, at: 0, context: context)
    }

    /// Moves locations within a list
    /// - Parameters:
    ///   - list: The list containing the locations
    ///   - source: The source indices of the locations to move
    ///   - destination: The destination index
    ///   - context: The SwiftData model context
    /// - Throws: LocationListService.Error if the operation fails
    static func moveLocations(
        in list: LocationList,
        from source: IndexSet,
        to destination: Int,
        context: ModelContext
    ) throws {
        list.locations.move(fromOffsets: source, toOffset: destination)
        updateLocationOrders(in: list)
        list.isOptimized = false
        RouteService.clearCache()

        do {
            try context.save()
            Logger.success("Moved locations")
        } catch {
            Logger.error("Failed to save location move: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    /// Deletes locations from a list
    /// - Parameters:
    ///   - list: The list to delete locations from
    ///   - offsets: The indices of locations to delete
    ///   - context: The SwiftData model context
    /// - Throws: LocationListService.Error if the operation fails
    static func deleteLocations(
        in list: LocationList,
        at offsets: IndexSet,
        context: ModelContext
    ) throws {
        list.locations.remove(atOffsets: offsets)
        updateLocationOrders(in: list)
        list.isOptimized = false
        RouteService.clearCache()

        do {
            try context.save()
            Logger.success("Deleted locations")
        } catch {
            Logger.error("Failed to save location deletion: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    /// Updates the order of locations after optimization
    /// - Parameters:
    ///   - list: The list containing the locations
    ///   - reorderedLocations: The locations in their new order
    ///   - context: The SwiftData model context
    /// - Throws: LocationListService.Error if the operation fails
    static func updateLocationOrders(
        in list: LocationList,
        with reorderedLocations: [Location],
        context: ModelContext
    ) throws {
        // Create lookup map using coordinate hash
        let locationMap = Dictionary(
            uniqueKeysWithValues: list.locations.map { location in
                (location.coordinateHash, location)
            }
        )

        // Update orders
        for (index, newLocation) in reorderedLocations.enumerated() {
            guard let existingLocation = locationMap[newLocation.coordinateHash] else {
                Logger.error("Location not found during reordering")
                throw Error.locationNotFound
            }
            existingLocation.order = index
        }

        list.isOptimized = true

        do {
            try context.save()
            verifyLocationOrder(in: list, expected: reorderedLocations)
            Logger.success("Updated location orders")
        } catch {
            Logger.error("Failed to save order updates: \(error.localizedDescription)")
            throw Error.saveFailed
        }
    }

    /// Reverts an optimization attempt
    /// - Parameters:
    ///   - list: The list to revert
    ///   - originalLocations: The original order of locations
    static func revertOptimization(
        in list: LocationList,
        to originalLocations: [Location]
    ) {
        updateLocationOrders(in: list)
        list.isOptimized = false
        Logger.warning("Reverted optimization to original order")
    }

    // MARK: - Private Helpers

    /// Updates the order property of all locations in a list
    private static func updateLocationOrders(in list: LocationList) {
        for (index, location) in list.locations.enumerated() {
            location.order = index
        }
    }

    /// Verifies that the location order matches the expected order
    private static func verifyLocationOrder(
        in list: LocationList,
        expected: [Location]
    ) {
        let expectedOrder = expected.map { $0.name }.joined(separator: ", ")
        let actualOrder = list.sortedLocations.map { $0.name }.joined(separator: ", ")

        Logger.info("New order in list: \(actualOrder)")

        if expectedOrder != actualOrder {
            Logger.warning("Order mismatch!")
            Logger.warning("Expected: \(expectedOrder)")
            Logger.warning("Actual: \(actualOrder)")
        }
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
