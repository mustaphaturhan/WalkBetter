import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.7
    @State private var opacity = 0.3
    @Environment(\.colorScheme) private var colorScheme

    var onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    // Gradient colors based on color scheme
    private var gradientColors: [Color] {
        colorScheme == .dark
            ? [Color(hex: "#002B22"), Color(hex: "#042D3E")]
            : [Color(hex: "#00FFCC"), Color(hex: "#1AB8FC")]
    }

    var body: some View {
        if isActive {
            LocationListsView()
        } else {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(
                            color: (colorScheme == .dark ?
                                Color(hex: "#000") : Color(hex: "#1AB8FC")).opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 5
                        )

                    Text("WalkBetter")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            if let onComplete = onComplete {
                                onComplete()
                            } else {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview("Light Mode") {
    SplashScreenView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SplashScreenView()
        .preferredColorScheme(.dark)
}
