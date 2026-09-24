import SwiftUI

/// One onboarding page: an introduction slide, or the Apple Health step.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let healthState: HealthAccessState

    var body: some View {
        switch page {
        case let .slide(index):
            OnboardingSlideView(slide: OnboardingSlide.all[index])
        case .health:
            OnboardingHealthPage(state: healthState)
        }
    }
}

#if DEBUG
#Preview {
    OnboardingPageView(page: .slide(0), healthState: .undecided)
}
#endif
