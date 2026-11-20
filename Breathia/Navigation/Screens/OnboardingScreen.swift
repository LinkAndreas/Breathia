import SwiftUI

/// Onboarding, which closes itself when done.
struct OnboardingScreen: View {
    let screens: AppScreens

    var body: some View {
        let settingsStore = screens.settingsStore
        OnboardingView(
            healthAccess: HealthAccessStep.make(mindfulMinutes: screens.mindfulMinutes, settingsStore: settingsStore),
            completion: {
                settingsStore.completeOnboarding()
                // New users learn the app from onboarding, not from a list of changes.
                settingsStore.markWhatsNewSeen(WhatsNew.version)
                screens.navigator.closeOnboarding()
            }
        )
    }
}
