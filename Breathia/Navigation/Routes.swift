import NavigationKit

// Every destination in the app as a plain value. `AppRoutes` maps each case to its
// screen, so screens never construct navigation themselves — they only report
// intents through closures. Routes are `nonisolated` because the app target
// defaults to the main actor, and routes must be `Sendable`.

/// Every route type in the app. `NavigationTests` checks that each one has a screen, so add new
/// route types here.
nonisolated enum AppRouteTypes {
    static let all: [any Route.Type] = [
        BreatheRoute.self, HistoryRoute.self, SettingsRoute.self,
        SensorRoute.self, SessionRoute.self, OnboardingRoute.self,
    ]
}

nonisolated enum BreatheRoute: Route {
    /// The searchable, filterable technique list.
    case home
    /// A technique's explanations and its Start button — pushed in the tab bar,
    /// shown in the detail column next to `home` in the split view.
    case technique(Technique.ID)

    /// Give the page and its floating Start button the whole screen on iPhone.
    var hidesTabBar: Bool {
        if case .technique = self { true } else { false }
    }
}

nonisolated enum HistoryRoute: Route {
    case list
    case session(SessionRecord.ID)
    /// The detail column before a session is chosen.
    case noSelection
}

nonisolated enum SettingsRoute: Route {
    /// Every setting in one form in the tab bar; the categories, like the Settings
    /// app, in the split view's content column.
    case home
    case page(SettingsPage)
}

/// One settings category or info page.
nonisolated enum SettingsPage: Hashable, Codable, Sendable {
    case sensor
    case breathing
    case biofeedback
    case health
    case appearance
    case history
    case privacy
    case aboutSensor
}

/// Finding and connecting the heart-rate sensor.
nonisolated enum SensorRoute: Route {
    case connect

    var presentation: PresentationStyle? { .sheet }
}

/// A live breathing session: a full-screen cover on iPhone and iPad, a sheet on the Mac.
nonisolated enum SessionRoute: Route {
    case run(Technique.ID)

    var presentation: PresentationStyle? { .cover }
}

/// First-run onboarding, presented modally over the app. `AppNavigator` picks the
/// style, which depends on the window's width.
nonisolated enum OnboardingRoute: Route {
    case welcome
}
