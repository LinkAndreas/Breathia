import SwiftUI

struct StatusDot: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? Theme.Palette.connected : Theme.Palette.disconnected)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        StatusDot(isActive: true)
        StatusDot(isActive: false)
    }
    .padding()
}
#endif
