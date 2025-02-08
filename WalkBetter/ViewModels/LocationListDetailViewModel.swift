import SwiftUI
import SwiftData
import MapKit

@Observable
class LocationListDetailViewModel {
    var list: LocationList
    var showingLocationPicker = false
    var showingStartingPointPicker = false
    var showingMapView = false
    var isOptimizing = false
    var errorMessage: String?
    var showError = false
    var editMode = EditMode.inactive

    init(list: LocationList) {
        self.list = list
    }

    var isRouteOptimized: Bool {
        list.isOptimized
    }

    func optimizeRoute() {
        isOptimizing = true
        RouteService.clearCache()

        // Save original locations in case optimization fails
        let originalLocations = list.sortedLocations

        RouteOptimizationService.optimizeRoute(for: originalLocations) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let routeResult):
                    do {
                        guard let context = self.list.modelContext else {
                            throw LocationListError.modelContextMissing
                        }

                        try withAnimation(.easeInOut(duration: 0.5)) {
                            try RouteOptimizationService.updateLocationOrders(
                                in: self.list,
                                with: routeResult.optimizedLocations,
                                context: context
                            )
                        }
                    } catch {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            LocationListService.revertOptimization(in: self.list, to: originalLocations)
                        }
                        self.handleError(error, operation: "Optimize Route")
                    }
                case .failure(let error):
                    withAnimation(.easeInOut(duration: 0.3)) {
                        LocationListService.revertOptimization(in: self.list, to: originalLocations)
                    }
                    self.handleError(error, operation: "Optimize Route")
                }
                self.isOptimizing = false
            }
        }
    }

    func addLocation(from mapItem: MKMapItem) {
        guard let context = list.modelContext else {
            handleError(LocationListError.modelContextMissing, operation: "Add Location")
            return
        }

        do {
            try LocationListService.addLocation(
                from: mapItem,
                to: list,
                context: context
            )
        } catch {
            handleError(error, operation: "Add Location")
        }
    }

    func addStartingPoint(from mapItem: MKMapItem) {
        guard let context = list.modelContext else {
            handleError(LocationListError.modelContextMissing, operation: "Add Starting Point")
            return
        }

        do {
            try LocationListService.addStartingPoint(
                from: mapItem,
                to: list,
                context: context
            )
        } catch {
            handleError(error, operation: "Add Starting Point")
        }
    }

    func moveLocations(from source: IndexSet, to destination: Int) {
        guard let context = list.modelContext else {
            handleError(LocationListError.modelContextMissing, operation: "Move Locations")
            return
        }

        do {
            try LocationListService.moveLocations(
                in: list,
                from: source,
                to: destination,
                context: context
            )
        } catch {
            handleError(error, operation: "Move Locations")
        }
    }

    func deleteLocations(at offsets: IndexSet) {
        guard let context = list.modelContext else {
            handleError(LocationListError.modelContextMissing, operation: "Delete Locations")
            return
        }

        do {
            try LocationListService.deleteLocations(in: list, at: offsets, context: context)
        } catch {
            handleError(error, operation: "Delete Locations")
        }
    }

    func openInAppleMaps() {
        do {
            try MapNavigationService.openInAppleMaps(locations: list.sortedLocations)
        } catch {
            handleError(error, operation: "Open in Apple Maps")
        }
    }

    func openInGoogleMaps() {
        do {
            try MapNavigationService.openInGoogleMaps(locations: list.sortedLocations)
        } catch {
            handleError(error, operation: "Open in Google Maps")
        }
    }

    private func handleError(_ error: Error, operation: String) {
        ErrorHandlingService.handleError(error, operation: operation) { message in
            self.errorMessage = message
            self.showError = true
        }
    }
}
