import SwiftUI

struct OptimizedRouteActionsView: View {
    let showMapAction: () -> Void
    let openInAppleMapsAction: () -> Void
    let openInGoogleMapsAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            OptimizedRouteHeaderView()
            RoutePreviewButton(action: showMapAction)
            NavigationOptionsView(
                openInAppleMapsAction: openInAppleMapsAction,
                openInGoogleMapsAction: openInGoogleMapsAction
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

#Preview {
    List {
        OptimizedRouteActionsView(
            showMapAction: {},
            openInAppleMapsAction: {},
            openInGoogleMapsAction: {}
        )
    }
    .listStyle(.insetGrouped)
}
