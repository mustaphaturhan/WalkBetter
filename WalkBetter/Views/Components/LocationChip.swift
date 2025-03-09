import SwiftUI

struct LocationChip: View {
    let location: Location
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 24, height: 24)

                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Text(location.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

#Preview("Single Location") {
    LocationChip(location: Location(name: "Grand Place", latitude: 50.8467, longitude: 4.3499))
        .padding()
}

#Preview("Without Icon") {
    LocationChip(location: Location(name: "Grand Place", latitude: 50.8467, longitude: 4.3499), showIcon: false)
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

#Preview("Dark Mode") {
    LocationChip(location: Location(name: "Grand Place", latitude: 50.8467, longitude: 4.3499))
        .padding()
        .preferredColorScheme(.dark)
}
