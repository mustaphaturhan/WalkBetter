import SwiftUI

struct NetworkStatusView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce, options: .repeating, value: isAnimating)

            Text("No Internet Connection")
                .font(.headline)

            Text("Please check your connection and try again")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    NetworkStatusView()
}
