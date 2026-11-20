import SwiftUI

/// Onboarding as a modal: a cover in the tab bar, a form sheet elsewhere. It can
/// only be left through its own buttons.
struct OnboardingModal: View {
    let screens: AppScreens

    var body: some View {
        NavigationStack {
            screens.onboardingScreen()
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        }
        #if os(macOS)
        // Room for the illustrations and two-line descriptions in the Mac sheet.
        .frame(minWidth: 520, idealWidth: 560, minHeight: 680, idealHeight: 720)
        #endif
        .presentationSizing(.form)
        .interactiveDismissDisabled()
    }
}
