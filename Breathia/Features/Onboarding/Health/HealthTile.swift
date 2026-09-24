import SwiftUI

/// A white heart on a pink tile, echoing the Health app.
struct HealthTile: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 1, green: 0.42, blue: 0.55), Color(red: 1, green: 0.2, blue: 0.36)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 104, height: 104)
            .overlay {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .pink.opacity(0.3), radius: 12, y: 6)
            .accessibilityHidden(true)
    }
}
