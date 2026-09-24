import SwiftUI

/// A slide's illustration, in the slide's colour.
struct OnboardingIllustration: View {
    let slide: OnboardingSlide

    var body: some View {
        let tint = slide.tint
        switch slide.illustration {
        case .breathing:
            ZStack {
                Circle().fill(tint.opacity(0.10)).frame(width: 150, height: 150)
                Circle().fill(tint.opacity(0.18)).frame(width: 108, height: 108)
                Circle()
                    .fill(tint.gradient)
                    .frame(width: 66, height: 66)
                    .shadow(color: tint.opacity(0.5), radius: 14)
            }

        case .heartRate:
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 150, height: 150)
                Image(systemName: "heart.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(tint.gradient)
                    .symbolEffect(.pulse)
                    .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .techniques:
            TechniquePreviewList()

        case .ready:
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 150, height: 150)
                Circle()
                    .fill(tint.gradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: tint.opacity(0.45), radius: 14, y: 6)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 32) {
            ForEach(OnboardingSlide.all.indices, id: \.self) { index in
                OnboardingIllustration(slide: OnboardingSlide.all[index])
            }
        }
        .padding()
    }
}
#endif
