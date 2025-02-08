import SwiftUI
import SwiftData

struct NewLocationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Create New List")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Give your walking list a memorable name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            TextField("", text: $name)
                .focused($isNameFieldFocused)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 24)
                .padding(.top, 32)

            Text("You can add up to \(LocationList.maxLocations) locations")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            Button(action: createList) {
                Text("Create List")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isNameValid ?
                                Color.blue.gradient :
                                Color.gray.opacity(0.3).gradient
                            )
                    )
                    .foregroundColor(isNameValid ? .white : .gray)
            }
            .disabled(!isNameValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            isNameFieldFocused = true
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createList() {
        let list = LocationList(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(list)
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: LocationList.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return NavigationStack {
        NewLocationListView()
    }
    .modelContainer(container)
}

