import SwiftUI

struct OnboardingSlide {
    enum Illustration { case breathing, heartRate, techniques, ready }

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let illustration: Illustration
    /// Mixed like the technique colours (same lightness and chroma), so every page
    /// has its own hue while the set still looks like one palette.
    let tint: Color

    static let all = [
        OnboardingSlide(
            title: "common.breathe",
            subtitle: "onboarding.aCalmerWay",
            illustration: .breathing,
            tint: Color(oklch: 0.62, chroma: 0.15, hue: 200)
        ),
        OnboardingSlide(
            title: "onboarding.connectPolarH10",
            subtitle: "onboarding.pairYourChestStrap",
            illustration: .heartRate,
            tint: Color(oklch: 0.62, chroma: 0.17, hue: 20)
        ),
        OnboardingSlide(
            title: "onboarding.chooseATechnique",
            subtitle: "onboarding.boxBreathingResonanceBreathing",
            illustration: .techniques,
            tint: Color(oklch: 0.62, chroma: 0.15, hue: 290)
        ),
        OnboardingSlide(
            title: "onboarding.readyToBegin",
            subtitle: "onboarding.startYourFirstBreathing",
            illustration: .ready,
            tint: Color(oklch: 0.62, chroma: 0.15, hue: 150)
        ),
    ]
}
