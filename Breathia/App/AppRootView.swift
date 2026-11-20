import SwiftUI

/// The app's window: tabs when it's narrow, a split view when it's wide, with the
/// sheets, the running session, and questions over it. Applies the user's
/// appearance preference to the whole window.
struct AppRootView: View {
    let screens: AppScreens

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Whether the window is wide enough for the split view.
    private var isRegularWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        true
        #endif
    }

    private var navigator: AppNavigator { screens.navigator }

    var body: some View {
        @Bindable var navigator = navigator
        ZStack {
            Group {
                if isRegularWidth {
                    SplitLayout(screens: screens)
                } else {
                    TabLayout(screens: screens)
                }
            }
            .onChange(of: isRegularWidth, initial: true) { _, isRegular in
                navigator.windowWidthDidChange(isRegular: isRegular)
            }
            .sheet(isPresented: $navigator.isShowingSensor) {
                NavigationStack {
                    SensorSheetView(onDone: { navigator.isShowingSensor = false })
                }
                .environment(screens.heartRateMonitor)
            }
            #if os(iOS)
            // Behind a session, the app is out of reach for VoiceOver too.
            .accessibilityHidden(navigator.runningTechniqueID != nil)
            .fullScreenCover(isPresented: isPresentingOnboarding(as: .cover)) {
                OnboardingModal(screens: screens)
            }
            #endif

            #if os(iOS)
            if let techniqueID = navigator.runningTechniqueID {
                SessionLayer(techniqueID: techniqueID, screens: screens)
                    // Slides up and away as a full-screen cover does.
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
            #endif
        }
        #if os(iOS)
        .animation(.smooth, value: navigator.runningTechniqueID)
        #else
        .sheet(isPresented: isRunningSession) {
            if let techniqueID = navigator.runningTechniqueID {
                SessionLayer(techniqueID: techniqueID, screens: screens)
            }
        }
        #endif
        .sheet(isPresented: isPresentingOnboarding(as: .sheet)) {
            OnboardingModal(screens: screens)
        }
        .sheet(isPresented: $navigator.isShowingWhatsNew) {
            screens.whatsNewScreen()
                .presentationSizing(.form)
        }
        .alert(
            navigator.dialog.map { Text($0.title) } ?? Text(verbatim: ""),
            isPresented: Binding(
                get: { navigator.dialog != nil },
                set: { isPresented in
                    if !isPresented { navigator.answer(nil) }
                }
            ),
            presenting: navigator.dialog
        ) { dialog in
            ForEach(dialog.actions) { action in
                Button(role: action.role) {
                    navigator.answer(action.id)
                } label: {
                    Text(action.title)
                }
            }
        } message: { dialog in
            if let message = dialog.message {
                Text(message)
            }
        }
        // Applies to every list, form, and scroll view, including sheets.
        .scrollIndicators(.hidden)
        #if os(macOS)
        // Grouped sections like System Settings; the Mac's default form style is a flat
        // column. Forms shown in sheets set it themselves, as sheets don't inherit it.
        .formStyle(.grouped)
        #endif
        #if os(iOS)
        // The app's controls take the icon's main color, and change with it. A Mac keeps its
        // own colors: its sidebar follows the system accent color whatever the app sets, so a
        // theme would only ever be partial there. The icon changes in the Dock alone.
        .tint(screens.appIconStore.current.palette.accent)
        #endif
        .preferredColorScheme(screens.settingsStore.settings.appearance.colorScheme)
    }

    private func isPresentingOnboarding(as presentation: OnboardingPresentation) -> Binding<Bool> {
        Binding(
            get: { navigator.onboarding == presentation },
            set: { isPresented in
                if !isPresented, navigator.onboarding == presentation { navigator.closeOnboarding() }
            }
        )
    }

    #if os(macOS)
    /// The session sheet; Escape closes it, and the session ends with it.
    private var isRunningSession: Binding<Bool> {
        Binding(
            get: { navigator.runningTechniqueID != nil },
            set: { isPresented in
                if !isPresented { navigator.endSession() }
            }
        )
    }
    #endif
}

extension AppRootView {
    init(dependencies: AppDependencies) {
        self.init(screens: dependencies.screens)
    }
}

private extension Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

#if DEBUG
#Preview("Main") {
    AppRootView(dependencies: AppDependencies.preview())
}
#endif

#if DEBUG
#Preview("First Launch") {
    AppRootView(dependencies: AppDependencies.preview(hasCompletedOnboarding: false))
}
#endif
