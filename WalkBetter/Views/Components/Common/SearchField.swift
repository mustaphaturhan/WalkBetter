import SwiftUI

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    let onClear: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isFocused ? .blue : .secondary)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: isFocused) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = newValue
                        }
                    }
            }

            if !text.isEmpty {
                Button(action: {
                    withAnimation {
                        text = ""
                        onClear()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
                        .blendMode(.overlay)
                }
        }
        .animation(.default, value: text)
    }
}

#Preview("Empty") {
    Group {
        SearchField(
            text: .constant(""),
            placeholder: "Search locations...",
            onClear: {}
        )
        .padding()
        .background(Color(.systemGroupedBackground))

        SearchField(
            text: .constant(""),
            placeholder: "Search locations...",
            onClear: {}
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }
}

#Preview("With Text") {
    Group {
        SearchField(
            text: .constant("Ankara"),
            placeholder: "Search locations...",
            onClear: {}
        )
        .padding()
        .background(Color(.systemGroupedBackground))

        SearchField(
            text: .constant("Ankara"),
            placeholder: "Search locations...",
            onClear: {}
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var text = ""

        var body: some View {
            SearchField(
                text: $text,
                placeholder: "Search locations...",
                onClear: {}
            )
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
