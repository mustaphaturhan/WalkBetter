import SwiftUI

struct NavigationOptionsView: View {
    let openInAppleMapsAction: () -> Void
    let openInGoogleMapsAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Open Directions With")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: openInAppleMapsAction) {
                HStack(spacing: 12) {
                    Image("AMaps")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text("Apple Maps")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button(action: openInGoogleMapsAction) {
                HStack(spacing: 12) {
                    Image("GMaps")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text("Google Maps")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationOptionsView(
        openInAppleMapsAction: {},
        openInGoogleMapsAction: {}
    )
    .padding()
}
