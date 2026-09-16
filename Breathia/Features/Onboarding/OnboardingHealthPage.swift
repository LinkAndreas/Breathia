import SwiftUI

/// What the onboarding's Apple Health step can do. Provided by the app layer, so
/// the onboarding screens stay unaware of HealthKit.
struct HealthAccessStep {
    /// Where the step starts: `.allowed` when onboarding is shown again after the
    /// user already chose to save mindful minutes, otherwise `.undecided`.
    let initialState: HealthAccessState
    /// Shows the system Health permission sheet and returns whether saving
    /// mindful minutes is allowed. Updates the app's setting accordingly.
    let requestAccess: @MainActor () async -> Bool
    /// The user chose not to save mindful minutes.
    let decline: @MainActor () -> Void
}

enum HealthAccessState: Equatable {
    case undecided
    case requesting
    case allowed
    case declined

    var isPending: Bool { self == .undecided || self == .requesting }
}

/// The onboarding page asking whether sessions should be saved to Apple Health.
struct OnboardingHealthPage: View {
    let state: HealthAccessState

    var body: some View {
        VStack(spacing: 18) {
            HealthTile()

            Text("common.saveMindfulMinutes")
                .font(.system(size: 27, weight: .bold))
                .multilineTextAlignment(.center)

            Text("onboarding.health.addEachBreathingSession")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 300)

            Label("onboarding.health.breathiaOnlyWrites", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            outcome
                .frame(minHeight: 24)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy, value: state)
    }

    @ViewBuilder
    private var outcome: some View {
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

/// A white heart on a pink tile, echoing the Health app.
private struct HealthTile: View {
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

#if DEBUG
#Preview {
    OnboardingHealthPage(state: .undecided)
}
#endif
