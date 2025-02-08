import MapKit
import SwiftData
import SwiftUI

struct LocationListDetailView: View {
    @State private var viewModel: LocationListDetailViewModel

    init(list: LocationList) {
        _viewModel = State(
            initialValue: LocationListDetailViewModel(list: list))
    }

    var body: some View {
        Group {
            if viewModel.list.locations.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "mappin.circle.fill",
                        title: "Add Your First Location",
                        subtitle:
                            "Start by adding locations to create your perfect walking route",
                        buttonTitle: "Add Starting Point",
                        buttonAction: {
                            viewModel.showingStartingPointPicker = true
                        },
                        features: [
                            (
                                icon: "location.circle.fill",
                                title: "Start Nearby",
                                description:
                                    "Choose a starting point close to your location"
                            ),
                            (
                                icon: "map.fill",
                                title: "Plan Your Stops",
                                description:
                                    "Add up to \(LocationList.maxLocations) interesting locations to visit"
                            ),
                            (
                                icon: "wand.and.stars.inverse",
                                title: "Optimize Route",
                                description:
                                    "Let WalkBetter find the most efficient path"
                            ),
                        ]
                    )
                }
            } else {
                List {
                    // Locations section
                    Section {
                        if viewModel.list.canAddMoreLocations {
                            Button {
                                viewModel.showingStartingPointPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Add Starting Point")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }

                        ForEach(viewModel.list.sortedLocations) { location in
                            LocationItemView(
                                location: location,
                                isRouteOptimized: viewModel.isRouteOptimized,
                                isFirst: location
                                    == viewModel.list.sortedLocations.first,
                                isLast: location
                                    == viewModel.list.sortedLocations.last,
                                index: viewModel.list.sortedLocations
                                    .firstIndex(of: location),
                                showDragHandle: !viewModel.isRouteOptimized
                                    && viewModel.editMode == .inactive
                            )
                        }
                        .onDelete(perform: viewModel.deleteLocations)
                        .onMove(
                            perform: viewModel.isRouteOptimized
                                ? nil : viewModel.moveLocations)

                        if viewModel.list.canAddMoreLocations {
                            Button {
                                viewModel.showingLocationPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Add Location")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    } header: {
                        Text("Locations (\(viewModel.list.locations.count))")
                    }

                    // Optimize section
                    if viewModel.list.canOptimize {
                        Section {
                            if viewModel.isRouteOptimized {
                                OptimizedRouteActionsView(
                                    showMapAction: {
                                        viewModel.showingMapView = true
                                    },
                                    openInAppleMapsAction: viewModel
                                        .openInAppleMaps,
                                    openInGoogleMapsAction: viewModel
                                        .openInGoogleMaps
                                )
                            } else {
                                OptimizeRouteButtonView(
                                    isOptimizing: viewModel.isOptimizing,
                                    action: viewModel.optimizeRoute
                                )
                            }
                        }
                    } else if !viewModel.list.locations.isEmpty {
                        Section {
                            HStack(spacing: 16) {
                                Image(systemName: "wand.and.stars")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Route Optimization")
                                        .font(.headline)
                                    Text("Add \(LocationList.minLocations - viewModel.list.locations.count) more location\(LocationList.minLocations - viewModel.list.locations.count == 1 ? "" : "s") to optimize")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(viewModel.list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !viewModel.list.locations.isEmpty
                    && !viewModel.isRouteOptimized
                {
                    EditButton()
                }
            }
        }
        .environment(\.editMode, $viewModel.editMode)
        .sheet(isPresented: $viewModel.showingLocationPicker) {
            LocationSearchView(
                onLocationSelected: { viewModel.addLocation(from: $0) },
                title: "Add Location",
                listLocations: viewModel.list.locations
            )
        }
        .sheet(isPresented: $viewModel.showingStartingPointPicker) {
            LocationSearchView(
                onLocationSelected: { viewModel.addStartingPoint(from: $0) },
                title: "Add Starting Point",
                listLocations: viewModel.list.locations
            )
        }
        .sheet(isPresented: $viewModel.showingMapView) {
            NavigationStack {
                LocationMapView(list: viewModel.list)
            }
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            })
    }
}

#Preview("With Locations") {
    do {
        let container = try PreviewHelperService.createPreviewContainer()
        let list = PreviewHelperService.createSampleList(
            in: container.mainContext)

        return NavigationStack {
            LocationListDetailView(list: list)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

#Preview("Empty List") {
    do {
        let container = try PreviewHelperService.createPreviewContainer()
        let list = PreviewHelperService.createSampleList(
            in: container.mainContext,
            name: "New Walking Route",
            withLocations: false
        )

        return NavigationStack {
            LocationListDetailView(list: list)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

#Preview("London Tour") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createLondonList(in: container.mainContext)
        return NavigationStack {
            LocationListDetailView(list: list)
        }
    }
}

#Preview("Rome Tour") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createRomeList(in: container.mainContext)
        return NavigationStack {
            LocationListDetailView(list: list)
        }
    }
}

#Preview("Amsterdam Tour") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createAmsterdamList(in: container.mainContext)
        return NavigationStack {
            LocationListDetailView(list: list)
        }
    }
}

#Preview("Istanbul Tour") {
    PreviewHelperService.previewWithContainer { container in
        let list = PreviewHelperService.createIstanbulList(in: container.mainContext)
        return NavigationStack {
            LocationListDetailView(list: list)
        }
    }
}
