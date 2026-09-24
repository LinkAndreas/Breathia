import SwiftUI

struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 18) {
            OnboardingIllustration(slide: slide)
                // The same height on every page, so titles don't jump while swiping.
                .frame(height: 190)
                .accessibilityHidden(true)

            Text(slide.title)
                .font(.system(size: 27, weight: .bold))
                .multilineTextAlignment(.center)

            Text(slide.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    OnboardingSlideView(slide: OnboardingSlide.all[1])
}
#endif
