import SwiftData
import SwiftUI

struct LocationListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationList.createdAt, order: .reverse) private var lists: [LocationList]
    @State private var showingNewListSheet = false
    @State private var listToDelete: LocationList?

    var body: some View {
        NavigationStack {
            ScrollView {
                if lists.isEmpty {
                    EmptyStateView(
                        icon: "figure.walk",
                        title: "Start Your Walking Adventure",
                        subtitle: "Create your first list to plan the perfect walking route",
                        buttonTitle: "Create List",
                        buttonAction: { showingNewListSheet = true },
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
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(lists) { list in
                            NavigationLink(destination: LocationListDetailView(list: list)) {
                                LocationListCard(list: list)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    listToDelete = list
                                } label: {
                                    Label("Delete List", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    listToDelete = list
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewListSheet = true
                    } label: {
                        Label("Add List", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewListSheet) {
                NavigationStack {
                    NewLocationListView()
                }
                .presentationDetents([.medium])
            }
            .modifier(DeleteListConfirmationDialog(
                listToDelete: $listToDelete,
                onDelete: { list in
                    ListManagementService.deleteList(list, context: modelContext)
                    listToDelete = nil
                }
            ))
        }
    }
}

#Preview("With Lists") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LocationList.self, configurations: config)

        // Create sample lists
        ListManagementService.createSampleLists(in: container.mainContext)

        return LocationListsView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

#Preview("Empty State") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LocationList.self, configurations: config)
        return LocationListsView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
