import SwiftData
import SwiftUI

struct LocationListCard: View {
    let list: LocationList

    // Computed properties for better readability
    private var locationCount: Int {
        list.locations.count
    }

    private var statusColor: Color {
        if list.isOptimized {
            return .green
        } else if list.canOptimize {
            return .blue
        } else {
            return .secondary
        }
    }

    private var statusIcon: String {
        if list.isOptimized {
            return "checkmark.circle.fill"
        } else if list.canOptimize {
            return "arrow.triangle.swap"
        } else {
            return "plus.circle"
        }
    }

    private var statusText: String {
        if list.isOptimized {
            return "Optimized Route"
        } else if list.canOptimize {
            return "Ready to Optimize"
        } else {
            return "Need \(LocationList.minLocations - locationCount) more"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with list name and status badge
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(list.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption)

                        Text(statusText)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(locationCount) location\(locationCount != 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if !list.locations.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(list.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, statusColor.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 12)

            // Location chips
            if !list.locations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Location chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(list.sortedLocations.prefix(5)) { location in
                                LocationChip(location: location)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            if locationCount > 5 {
                                ZStack {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 36, height: 36)

                                    Text("+\(locationCount - 5)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Route info (if optimized)
                    if list.isOptimized {
                        HStack(spacing: 16) {
                            // We could add actual route statistics here if available
                            routeInfoItem(icon: "figure.walk", label: "Walking Route")
                            routeInfoItem(icon: "arrow.triangle.turn.up.right.diamond", label: "Optimized Path")
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            } else {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)

                        Text("No locations added yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            }

            // Footer with action hints
            HStack {
                Spacer()

                Text(list.canOptimize && !list.isOptimized ? "Tap to optimize" : "Tap to view details")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func routeInfoItem(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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

#Preview("Dark Mode") {
    LocationListCard(
        list: {
            let list = LocationList(name: "Night Tour")
            list.locations = [
                Location(name: "Starting Point", latitude: 0, longitude: 0),
                Location(name: "Viewpoint", latitude: 1, longitude: 1),
                Location(name: "End Point", latitude: 2, longitude: 2),
            ]
            list.isOptimized = true
            return list
        }()
    )
    .padding()
    .preferredColorScheme(.dark)
}
