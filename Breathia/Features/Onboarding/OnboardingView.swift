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
                    OnboardingPageView(page: pages[index], healthState: healthState)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            // No swiping between pages on a Mac: Next slides the following page in.
            OnboardingPageView(page: pages[page], healthState: healthState)
                .id(page)
                .frame(maxHeight: .infinity)
                .transition(.push(from: .trailing))
            #endif

            PageIndicator(count: pages.count, current: page, tint: tint)
                .padding(.bottom, 24)

            OnboardingControls(
                page: page,
                tint: tint,
                isLastPage: isLastPage,
                isOnPendingHealthStep: isOnPendingHealthStep,
                isRequestingHealth: healthState == .requesting,
                onConnectHealth: connectHealth,
                onDeclineHealth: declineHealth,
                onAdvance: advance
            )
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

#if DEBUG
#Preview {
    OnboardingView(
        healthAccess: HealthAccessStep(initialState: .undecided, requestAccess: { true }, decline: {}),
        completion: {}
    )
}
#endif
