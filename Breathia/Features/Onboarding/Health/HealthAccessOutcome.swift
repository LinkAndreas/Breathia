import SwiftUI

/// How the Health step turned out: a confirmation once saving is allowed, or where
/// to turn it on later once declined.
struct HealthAccessOutcome: View {
    let state: HealthAccessState

    var body: some View {
        switch state {
        case .allowed:
            Label("onboarding.health.mindfulMinutes", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
        case .declined:
            Text("onboarding.health.youCanTurnThis")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        case .undecided, .requesting:
            EmptyView()
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        HealthAccessOutcome(state: .allowed)
        HealthAccessOutcome(state: .declined)
    }
    .padding()
}
#endif
