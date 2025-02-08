import SwiftUI

struct LocationMapMarker: View {
    let isFirst: Bool
    let isLast: Bool
    let index: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 44, height: 44)
                .shadow(radius: 2)

            if isFirst {
                Image(systemName: "flag.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            } else if isLast {
                Image(systemName: "flag.checkered")
                    .font(.title)
                    .foregroundStyle(.blue)
            } else if let index = index {
                Circle()
                    .fill(.red)
                    .frame(width: 32, height: 32)
                Text("\(index)")
                    .font(.callout.bold())
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("Regular") {
    LocationMapMarker(isFirst: false, isLast: false, index: 2)
}

#Preview("Start") {
    LocationMapMarker(isFirst: true, isLast: false, index: nil)
}

#Preview("End") {
    LocationMapMarker(isFirst: false, isLast: true, index: nil)
}
