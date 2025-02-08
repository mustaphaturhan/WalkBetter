import SwiftUI

struct OptimizedRouteHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Route Optimized")
                    .font(.headline)
                    .foregroundStyle(.green)
                Text("Your walking route has been optimized for efficiency")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    OptimizedRouteHeaderView()
        .padding()
}
