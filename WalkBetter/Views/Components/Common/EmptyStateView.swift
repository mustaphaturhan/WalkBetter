import SwiftUI

struct Feature {
    let icon: String
    let title: String
    let description: String
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonAction: () -> Void
    let features: [Feature]

    init(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        features: [(icon: String, title: String, description: String)]
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.features = features.map(Feature.init)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 40)

            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: 16) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: buttonAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .imageScale(.small)
                        Text(buttonTitle)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.element.title) { index, feature in
                    if index > 0 {
                        Divider()
                    }

                    FeatureItem(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description
                    )
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
            .padding(.top, 48)
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Empty List") {
    ScrollView {
        EmptyStateView(
            icon: "figure.walk",
            title: "Start Your Walking Adventure",
            subtitle: "Create your first list to plan the perfect walking route",
            buttonTitle: "Create List",
            buttonAction: {},
            features: [
                (
                    icon: "map",
                    title: "Plan Your Route",
                    description: "Add your favorite locations and create a perfect walking route"
                ),
                (
                    icon: "arrow.triangle.turn.up.right.circle",
                    title: "Optimize Automatically",
                    description: "Let WalkBetter find the most efficient path between locations"
                ),
                (
                    icon: "arrow.triangle.branch",
                    title: "Multiple Navigation Options",
                    description: "Open your route in Apple or Google Maps"
                )
            ]
        )
    }
}

#Preview("Empty Locations") {
    ScrollView {
        EmptyStateView(
            icon: "mappin.circle.fill",
            title: "Add Your First Location",
            subtitle: "Start by adding locations to create your perfect walking route",
            buttonTitle: "Add Location",
            buttonAction: {},
            features: [
                (
                    icon: "location.circle.fill",
                    title: "Start Nearby",
                    description: "Choose a starting point close to your location"
                ),
                (
                    icon: "map.fill",
                    title: "Plan Your Stops",
                    description: "Add up to 15 interesting locations to visit"
                ),
                (
                    icon: "wand.and.stars.inverse",
                    title: "Optimize Route",
                    description: "Let WalkBetter find the most efficient path"
                )
            ]
        )
    }
}
