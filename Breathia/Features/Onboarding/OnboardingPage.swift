import Foundation

/// A page of the onboarding: an introduction slide, or the Apple Health step.
enum OnboardingPage: Hashable {
    case slide(Int)
    case health
}
