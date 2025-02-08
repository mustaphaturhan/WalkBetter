import SwiftUI

struct OptimizeRouteButtonView: View {
    let isOptimizing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if isOptimizing {
                    ProgressView()
                        .frame(width: 20, height: 20)
                        .tint(.blue)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isOptimizing ? "Optimizing Route..." : "Optimize Walking Route")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Find the most efficient path between locations")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.08))
        }
        .buttonStyle(.plain)
        .disabled(isOptimizing)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    List {
        OptimizeRouteButtonView(isOptimizing: false, action: {})
        OptimizeRouteButtonView(isOptimizing: true, action: {})
    }
    .listStyle(.insetGrouped)
}
