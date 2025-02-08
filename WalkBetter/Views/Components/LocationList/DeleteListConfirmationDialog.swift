import SwiftUI
import SwiftData

struct DeleteListConfirmationDialog: ViewModifier {
    @Binding var listToDelete: LocationList?
    let onDelete: (LocationList) -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Delete List",
                isPresented: .init(
                    get: { listToDelete != nil },
                    set: { if !$0 { listToDelete = nil } }
                ),
                presenting: listToDelete
            ) { list in
                Button("Delete '\(list.name)'", role: .destructive) {
                    withAnimation {
                        onDelete(list)
                    }
                }
            } message: { list in
                Text("Are you sure you want to delete '\(list.name)'? This action cannot be undone.")
            }
    }
}

// Preview helper view
struct DeleteListConfirmationDialogPreview: View {
    @State private var listToDelete: LocationList?

    var body: some View {
        VStack {
            Text("Tap to show delete confirmation")
                .foregroundStyle(.secondary)

            Button("Delete List") {
                listToDelete = LocationList(name: "Sample List")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .modifier(DeleteListConfirmationDialog(
            listToDelete: $listToDelete,
            onDelete: { list in
                print("Would delete: \(list.name)")
                listToDelete = nil
            }
        ))
    }
}

#Preview("Delete Confirmation") {
    DeleteListConfirmationDialogPreview()
        .padding()
}
