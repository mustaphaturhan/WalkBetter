import SwiftUI

struct LocationChip: View {
    let location: Location

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(location.name)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview("Single Location") {
    LocationChip(location: Location(name: "Grand Place", latitude: 50.8467, longitude: 4.3499))
        .padding()
}

#Preview("Multiple Locations") {
    ScrollView(.horizontal) {
        HStack(spacing: 8) {
            LocationChip(location: Location(name: "Eiffel Tower", latitude: 48.8584, longitude: 2.2945))
            LocationChip(location: Location(name: "Louvre Museum", latitude: 48.8606, longitude: 2.3376))
            LocationChip(location: Location(name: "Notre-Dame", latitude: 48.8530, longitude: 2.3499))
            LocationChip(location: Location(name: "Arc de Triomphe", latitude: 48.8738, longitude: 2.2950))
        }
    }
    .padding()
}
