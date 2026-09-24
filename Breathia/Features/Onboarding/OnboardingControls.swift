import SwiftUI

/// The primary button, plus "Not Now" on the Health step. The second row keeps
/// its height on every page so the pages don't shift as they're swiped.
struct OnboardingControls: View {
    let page: Int
    /// The current page's colour.
    let tint: Color
    let isLastPage: Bool
    let isOnPendingHealthStep: Bool
    let isRequestingHealth: Bool
    let onConnectHealth: () -> Void
    let onDeclineHealth: () -> Void
    let onAdvance: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            if isOnPendingHealthStep {
                PrimaryActionButton(title: "onboarding.connectAppleHealth", tint: .pink, action: onConnectHealth)
                    .disabled(isRequestingHealth)
                Button("onboarding.notNow", action: onDeclineHealth)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(height: 44)
                    .disabled(isRequestingHealth)
            } else {
                PrimaryActionButton(title: isLastPage ? "onboarding.getStarted" : "onboarding.next", tint: tint, action: onAdvance)
                Color.clear
                    .frame(height: 44)
            }
        }
        .animation(.snappy, value: isOnPendingHealthStep)
        .animation(.easeInOut(duration: 0.4), value: page)
    }
}
