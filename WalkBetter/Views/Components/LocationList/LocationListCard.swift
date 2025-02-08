import SwiftData
import SwiftUI

struct LocationListCard: View {
    let list: LocationList

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(list.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(list.locations.count) locations")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !list.locations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(list.sortedLocations.prefix(5)) { location in
                            LocationChip(location: location)
                        }

                        if list.locations.count > 5 {
                            Text("+\(list.locations.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(
                    list.createdAt.formatted(date: .abbreviated, time: .omitted)
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()
                if list.canOptimize && !list.isOptimized {
                    Text("Ready to optimize")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else if list.isOptimized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("Optimized")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else if !list.canOptimize {
                    Text(
                        "Add \(LocationList.minLocations - list.locations.count) more locations to optimize"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview("Optimized List") {
    LocationListCard(
        list: {
            let list = LocationList(name: "Brussels Tour")
            list.locations = [
                Location(
                    name: "Grand Place", latitude: 50.8467, longitude: 4.3499),
                Location(
                    name: "Palace of Justice", latitude: 50.8354,
                    longitude: 4.3490),
                Location(
                    name: "Royal Palace", latitude: 50.8429, longitude: 4.3523),
            ]
            list.isOptimized = true
            return list
        }()
    )
    .padding()
}

#Preview("Ready to Optimize") {
    LocationListCard(
        list: {
            let list = LocationList(name: "Paris Highlights")
            list.locations = [
                Location(
                    name: "Eiffel Tower", latitude: 48.8584, longitude: 2.2945),
                Location(
                    name: "Louvre Museum", latitude: 48.8606, longitude: 2.3376),
                Location(
                    name: "Notre-Dame", latitude: 48.8530, longitude: 2.3499),
            ]
            return list
        }()
    )
    .padding()
}

#Preview("Needs More Locations") {
    LocationListCard(
        list: {
            let list = LocationList(name: "Weekend Walk")
            list.locations = [
                Location(name: "Starting Point", latitude: 0, longitude: 0)
            ]
            return list
        }()
    )
    .padding()
}

#Preview("Empty List") {
    LocationListCard(
        list: LocationList(name: "New Route")
    )
    .padding()
}
