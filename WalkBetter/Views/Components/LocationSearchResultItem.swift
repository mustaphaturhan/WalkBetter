import SwiftUI
import MapKit

struct LocationSearchResultItem: View {
    let mapItem: MKMapItem
    let isDuplicate: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mapItem.name ?? "Unknown Location")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if isDuplicate {
                    Text("Already added")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let address = formatAddress(from: mapItem.placemark) {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func formatAddress(from placemark: MKPlacemark) -> String? {
        var components: [String] = []

        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }

        if let locality = placemark.locality {
            components.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

#Preview("Regular") {
    LocationSearchResultItem(
        mapItem: MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(
                    latitude: 39.9334,
                    longitude: 32.8597
                ),
                addressDictionary: [
                    "Street": "Atatürk Boulevard",
                    "City": "Ankara",
                    "State": "Turkey"
                ]
            )
        ),
        isDuplicate: false
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Duplicate") {
    LocationSearchResultItem(
        mapItem: MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(
                    latitude: 39.9334,
                    longitude: 32.8597
                ),
                addressDictionary: [
                    "Street": "Atatürk Boulevard",
                    "City": "Ankara",
                    "State": "Turkey"
                ]
            )
        ),
        isDuplicate: true
    )
    .padding()
    .background(Color(.systemBackground))
}
