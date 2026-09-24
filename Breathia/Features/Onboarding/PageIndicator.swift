import SwiftUI

struct PageIndicator: View {
    let count: Int
    let current: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? tint : Theme.Palette.tertiaryLabel)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement()
        .accessibilityLabel("onboarding.pageIndicator \(current + 1) \(count)")
    }
}
