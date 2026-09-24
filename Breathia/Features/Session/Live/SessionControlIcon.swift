import SwiftUI

/// The symbol inside a session control, filling the circle's centre.
struct SessionControlIcon: View {
    let systemImage: String
    let diameter: CGFloat

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: diameter * 0.34, weight: .semibold))
            .contentTransition(.symbolEffect(.replace))
            .frame(width: diameter, height: diameter)
    }
}

#if DEBUG
#Preview {
    SessionControlIcon(systemImage: "pause.fill", diameter: 84)
}
#endif
