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
