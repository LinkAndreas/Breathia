import SwiftUI

/// One control on the session's controls page: a wide tinted button with its name
/// under it.
struct WatchSessionControlButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(tint.opacity(0.25), in: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(title))
            Text(title)
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
#Preview {
    WatchSessionControlButton(title: "common.pause", systemImage: "pause.fill", tint: .teal, action: {})
}
#endif
