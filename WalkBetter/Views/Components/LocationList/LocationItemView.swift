import SwiftUI
import SwiftData
import MapKit

struct LocationItemView: View {
    let location: Location
    let isRouteOptimized: Bool
    let isFirst: Bool
    let isLast: Bool
    let index: Int?
    let showDragHandle: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isRouteOptimized {
                ZStack {
                    Circle()
                        .fill(isFirst ? Color.green.opacity(0.1) :
                              isLast ? Color.blue.opacity(0.1) :
                              Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)

                    if isFirst {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if isLast {
                        Image(systemName: "flag.checkered")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    } else if let index = index {
                        Text("\(index)")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)

                if isRouteOptimized {
                    Text(isFirst ? "Starting Point" :
                         isLast ? "Final Destination" :
                         "Stop \(index ?? 0)")
                        .font(.caption)
                        .foregroundStyle(
                            isFirst ? .green :
                            isLast ? .blue :
                            .secondary
                        )
                } else {
                    Text("Lat: \(String(format: "%.4f", location.latitude)), Lon: \(String(format: "%.4f", location.longitude))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: location.order)
    }
}

#Preview {
    LocationItemView(
        location: Location(
            name: "Sample Location",
            latitude: 39.9020,
            longitude: 32.8602,
            order: 1
        ),
        isRouteOptimized: true,
        isFirst: false,
        isLast: false,
        index: 1,
        showDragHandle: true
    )
    .padding()
}
