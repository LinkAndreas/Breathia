import NavigationKit
import SwiftUI

/// Renders the app's navigation tree and applies the user's appearance
/// preference to the whole window. What each route shows is decided by `AppRoutes`.
struct AppRootView: View {
    let navigator: AppNavigator
    let routes: AppRoutes
    let settingsStore: SettingsStore
    let appIconStore: AppIconStore
    let supportStore: SupportStore

    @Environment(\.scenePhase) private var scenePhase

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// The split view's criterion — the same one NavigationKit's adaptive layout uses.
    private var isRegularWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        true
        #endif
    }

    var body: some View {
        NavigationRoot(store: navigator.store)
            .routes(routes)
            .onChange(of: isRegularWidth, initial: true) { _, isRegular in
                navigator.windowWidthDidChange(isRegular: isRegular)
            }
        #if os(iOS)
        .tabBarMinimizeBehavior(.never)
        #endif
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
        .tint(appIconStore.current.palette.accent)
        #endif
        .preferredColorScheme(settingsStore.settings.appearance.colorScheme)
        // The subscription can change while Breathia is in the background — cancelled in
        // Settings or the App Store, run out, refunded — so read it on every return.
        .task { await supportStore.refreshSubscription() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await supportStore.refreshSubscription() }
            }
        }
        #if os(macOS)
        // A Mac app stays active while its window is behind the App Store's.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await supportStore.refreshSubscription() }
        }
        #endif
        .onChange(of: supportStore.isConfirmedNonSupporter, initial: true) { _, hasNoSupport in
            if hasNoSupport {
                Task { await appIconStore.supportEnded() }
            }
        }
    }
}

extension AppRootView {
    init(dependencies: AppDependencies) {
        self.init(
            navigator: dependencies.navigator,
            routes: dependencies.routes,
            settingsStore: dependencies.settingsStore,
            appIconStore: dependencies.appIconStore,
            supportStore: dependencies.supportStore
        )
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
    let dependencies = AppDependencies.preview()
    AppRootView(
        navigator: dependencies.navigator,
        routes: dependencies.routes,
        settingsStore: dependencies.settingsStore,
        appIconStore: dependencies.appIconStore,
        supportStore: dependencies.supportStore
    )
}
#endif

#if DEBUG
#Preview("First Launch") {
    let dependencies = AppDependencies.preview(hasCompletedOnboarding: false)
    AppRootView(
        navigator: dependencies.navigator,
        routes: dependencies.routes,
        settingsStore: dependencies.settingsStore,
        appIconStore: dependencies.appIconStore,
        supportStore: dependencies.supportStore
    )
}
#endif
