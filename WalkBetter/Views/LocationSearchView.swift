import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LocationSearchViewModel()
    @State private var locationManager = LocationManager()
    @Environment(\.networkService) private var networkService
    let onLocationSelected: (MKMapItem) -> Void
    let title: String
    let listLocations: [Location]

    init(
        onLocationSelected: @escaping (MKMapItem) -> Void,
        title: String,
        listLocations: [Location] = []
    ) {
        self.onLocationSelected = onLocationSelected
        self.title = title
        self.listLocations = listLocations
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SearchField(
                        text: $viewModel.searchText,
                        placeholder: "Search locations...",
                        onClear: {
                            viewModel.clearSearch()
                        }
                    )
                    .padding(.horizontal)

                    if !networkService.isConnected {
                        NetworkStatusView()
                            .padding(.horizontal)
                    } else {
                        Group {
                            if viewModel.searchText.isEmpty {
                                quickOptionsSection
                            } else {
                                searchResultsSection
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.height(400), .large])
        .onAppear {
            // Set initial location context
            viewModel.userLocation = locationManager.userLocation
            viewModel.listLocations = listLocations

            // Request location once if we have permission
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
        .onChange(of: locationManager.isLoading) { _, isLoading in
            if !isLoading {
                // Location update completed, update the view model
                viewModel.userLocation = locationManager.userLocation
            }
        }
    }

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                if let location = locationManager.userLocation {
                    let placemark = MKPlacemark(coordinate: location)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = "Current Location"
                    if !viewModel.isLocationDuplicate(mapItem) {
                        onLocationSelected(mapItem)
                        dismiss()
                    }
                } else {
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestLocationPermission()
                    } else {
                        locationManager.requestLocation()
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 48, height: 48)
                        if locationManager.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Location")
                            .font(.headline)
                        if locationManager.userLocation == nil {
                            Text(locationManager.authorizationStatus == .notDetermined ? "Tap to enable location access" : "Location access required")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let location = locationManager.userLocation,
                                  viewModel.isCurrentLocationDuplicate(location) {
                            Text("Already added")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                }
                .overlay {
                    if let location = locationManager.userLocation,
                       viewModel.isCurrentLocationDuplicate(location) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.gray.opacity(0.1))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(
                locationManager.authorizationStatus == .denied ||
                (locationManager.userLocation.map(viewModel.isCurrentLocationDuplicate) ?? false)
            )
            .padding(.horizontal)
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isSearching {
                HStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.regular)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Searching locations")
                            .font(.headline)
                        Text("This might take a moment...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                }
                .padding(.horizontal)
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.bounce)

                    VStack(spacing: 8) {
                        Text("No locations found")
                            .font(.headline)
                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    let isDuplicate = viewModel.isLocationDuplicate(item)
                    Button {
                        if !isDuplicate {
                            onLocationSelected(item)
                            viewModel.clearSearch()
                            dismiss()
                        }
                    } label: {
                        LocationSearchResultItem(mapItem: item, isDuplicate: isDuplicate)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                            }
                            .overlay {
                                if isDuplicate {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.gray.opacity(0.1))
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isDuplicate)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview("Online") {
    PreviewHelperService.previewWithNetworkState {
        LocationSearchView(
            onLocationSelected: { _ in },
            title: "Add Location"
        )
    }
}

#Preview("Offline") {
    PreviewHelperService.previewWithNetworkState(isConnected: false) {
        LocationSearchView(
            onLocationSelected: { _ in },
            title: "Add Location"
        )
    }
}

// Environment key for network service
private struct NetworkServiceKey: EnvironmentKey {
    static let defaultValue = NetworkConnectivityService.shared
}

extension EnvironmentValues {
    var networkService: NetworkConnectivityService {
        get { self[NetworkServiceKey.self] }
        set { self[NetworkServiceKey.self] = newValue }
    }
}
