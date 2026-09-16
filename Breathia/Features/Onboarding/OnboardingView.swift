import SwiftUI

struct OnboardingView: View {
    /// The Apple Health step; `nil` on devices without Health, where it's skipped.
    let healthAccess: HealthAccessStep?
    let completion: () -> Void

    @State private var page = 0
    @State private var healthState: HealthAccessState = .undecided

    init(healthAccess: HealthAccessStep? = nil, completion: @escaping () -> Void) {
        self.healthAccess = healthAccess
        self.completion = completion
        _healthState = State(initialValue: healthAccess?.initialState ?? .undecided)
    }

    /// The introduction slides, then the Health step, then "Ready to Begin".
    private var pages: [OnboardingPage] {
        let slides = OnboardingSlide.all.indices
        var pages = slides.dropLast().map(OnboardingPage.slide)
        if healthAccess != nil {
            pages.append(.health)
        }
        pages.append(.slide(slides.last!))
        return pages
    }

    private var isLastPage: Bool {
        page == pages.count - 1
    }

    private var isOnPendingHealthStep: Bool {
        pages[page] == .health && healthState.isPending
    }

    /// The current page's colour, carried by its illustration, the page indicator,
    /// the primary button, and the background wash.
    private var tint: Color {
        switch pages[page] {
        case let .slide(index): OnboardingSlide.all[index].tint
        case .health: .pink
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("onboarding.skip", action: completion)
                    .foregroundStyle(.secondary)
                    .opacity(isLastPage ? 0 : 1)
                    .disabled(isLastPage)
            }
            .frame(height: 44)
            .padding(.horizontal, 20)

            #if os(iOS)
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            // No swiping between pages on a Mac: Next slides the following page in.
            pageView(pages[page])
                .id(page)
                .frame(maxHeight: .infinity)
                .transition(.push(from: .trailing))
            #endif

            PageIndicator(count: pages.count, current: page, tint: tint)
                .padding(.bottom, 24)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .readableContentWidth(560)
        .background {
            ZStack {
                Theme.Palette.background
                LinearGradient(colors: [tint.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: page)
        }
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        switch page {
        case let .slide(index):
            OnboardingSlideView(slide: OnboardingSlide.all[index])
        case .health:
            OnboardingHealthPage(state: healthState)
        }
    }

    /// The primary button, plus "Not Now" on the Health step. The second row keeps
    /// its height on every page so the pages don't shift as they're swiped.
    private var controls: some View {
        VStack(spacing: 4) {
            if isOnPendingHealthStep {
                PrimaryActionButton(title: "onboarding.connectAppleHealth", tint: .pink, action: connectHealth)
                    .disabled(healthState == .requesting)
                Button("onboarding.notNow", action: declineHealth)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(height: 44)
                    .disabled(healthState == .requesting)
            } else {
                PrimaryActionButton(title: isLastPage ? "onboarding.getStarted" : "onboarding.next", tint: tint, action: advance)
                Color.clear
                    .frame(height: 44)
            }
        }
        .animation(.snappy, value: isOnPendingHealthStep)
        .animation(.easeInOut(duration: 0.4), value: page)
    }

    private func advance() {
        if isLastPage {
            completion()
        } else {
            withAnimation { page += 1 }
        }
    }

    private func connectHealth() {
        guard let healthAccess, healthState == .undecided else { return }
        healthState = .requesting
        Task {
            let isAllowed = await healthAccess.requestAccess()
            withAnimation { healthState = isAllowed ? .allowed : .declined }
            // Let the confirmation register before moving on.
            try? await Task.sleep(for: .seconds(1.2))
            if pages[page] == .health {
                advance()
            }
        }
    }

    private func declineHealth() {
        healthAccess?.decline()
        withAnimation { healthState = .declined }
        advance()
    }
}

private enum OnboardingPage: Hashable {
    case slide(Int)
    case health
}

private struct OnboardingSlide {
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

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 18) {
            illustration
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

    @ViewBuilder
    private var illustration: some View {
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

/// A miniature of the Breathe list: a few real techniques, each in its own colour,
/// fading out toward the bottom to hint at the rest of the catalog.
private struct TechniquePreviewList: View {
    private static let techniqueIDs: [Technique.ID] = ["resonance", "box", "478", "sigh"]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(Self.techniqueIDs.enumerated()), id: \.element) { index, id in
                let technique = TechniqueCatalog.technique(withID: id)
                HStack(spacing: 10) {
                    TechniqueOrb(technique: technique, size: 24)
                    Text(technique.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(verbatim: technique.shortPattern)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(technique.tint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.Palette.elevated, in: .rect(cornerRadius: 12))
                .opacity(1 - Double(index) * 0.2)
            }
        }
        .frame(width: 260)
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? tint : Theme.Palette.tertiaryLabel)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement()
        .accessibilityLabel("onboarding.pageIndicator \(current + 1) \(count)")
    }
}

#if DEBUG
#Preview {
    OnboardingView(
        healthAccess: HealthAccessStep(initialState: .undecided, requestAccess: { true }, decline: {}),
        completion: {}
    )
}
#endif
