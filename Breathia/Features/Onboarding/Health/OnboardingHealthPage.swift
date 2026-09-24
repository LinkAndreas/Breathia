import SwiftUI

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

            HealthAccessOutcome(state: state)
                .frame(minHeight: 24)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy, value: state)
    }
}

#if DEBUG
#Preview {
    OnboardingHealthPage(state: .undecided)
}
#endif
