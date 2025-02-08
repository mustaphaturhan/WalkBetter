import Foundation
import MapKit
import SwiftUI

@Observable
class LocationSearchViewModel {
    var searchText = "" {
        didSet {
            if searchText != oldValue {
                search()
            }
        }
    }
    var searchResults: [MKMapItem] = []
    var isSearching = false
    private var searchTask: Task<Void, Never>?

    // Context properties
    var userLocation: CLLocationCoordinate2D?
    var listLocations: [Location] = []

    func isLocationDuplicate(_ mapItem: MKMapItem) -> Bool {
        let coordinate = mapItem.placemark.coordinate
        return listLocations.contains { location in
            // Use a small threshold for floating point comparison
            let latDiff = abs(location.latitude - coordinate.latitude)
            let lonDiff = abs(location.longitude - coordinate.longitude)
            return latDiff < 0.0001 && lonDiff < 0.0001 // Approximately 10 meters
        }
    }

    func isCurrentLocationDuplicate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        return isLocationDuplicate(mapItem)
    }

    func search() {
        // Cancel any existing search task
        searchTask?.cancel()

        if searchText.isEmpty {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // Create a new search task with debounce
        searchTask = Task {
            // Wait for 300ms before performing the search
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if the task was cancelled during the delay
            if !Task.isCancelled {
                await performSearch()
            }
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
        searchTask?.cancel()
    }

    private func performSearch() async {
        do {
            // If we have list locations, use them for context
            if !listLocations.isEmpty {
                let results = try await LocationSearchService.searchLocations(
                    query: searchText,
                    listLocations: listLocations
                )
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } else {
                // Otherwise, use user location if available
                let results = try await LocationSearchService.searchLocations(
                    query: searchText,
                    userLocation: userLocation
                )
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            }
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }

    deinit {
        searchTask?.cancel()
    }
}
