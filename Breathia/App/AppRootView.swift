import NavigationKit
import SwiftUI

/// Renders the app's navigation tree and applies the user's appearance
/// preference to the whole window. What each route shows is decided by `AppRoutes`.
struct AppRootView: View {
    let navigator: AppNavigator
    let routeBuilder: RouteBuilder
    let settingsStore: SettingsStore

    var body: some View {
        NavigationContainer(
            navigator: navigator.root,
            routeBuilder: routeBuilder
        )
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
        .preferredColorScheme(settingsStore.settings.appearance.colorScheme)
        // Lets pages such as a session's report keep their content off a partly folded
        // display's crease.
        .readsDisplayFold()
    }
}

extension AppRootView {
    init(dependencies: AppDependencies) {
        self.init(
            navigator: dependencies.navigator,
            routeBuilder: dependencies.routeBuilder,
            settingsStore: dependencies.settingsStore
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
        routeBuilder: dependencies.routeBuilder,
        settingsStore: dependencies.settingsStore
    )
}
#endif

#if DEBUG
#Preview("First Launch") {
    let dependencies = AppDependencies.preview(hasCompletedOnboarding: false)
    AppRootView(
        navigator: dependencies.navigator,
        routeBuilder: dependencies.routeBuilder,
        settingsStore: dependencies.settingsStore
    )
}
#endif
