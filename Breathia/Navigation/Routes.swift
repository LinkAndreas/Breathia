import Foundation

// Every destination in the app as a plain `Hashable` value. NavigationKit's
// `RouteBuilder` maps each case to its screen (see `AppRoutes`), so
// screens never construct navigation themselves — they only report intents
// through closures.

/// The iPad sidebar listing the app's sections.
enum AppSidebarRoute: Hashable {
    case sections
}

enum BreatheRoute: Hashable {
    /// The searchable, filterable technique list.
    case home
    /// A technique's explanations and its Start button — pushed on iPhone, shown
    /// in the detail column next to `home` on iPad.
    case technique(Technique.ID)
}

enum HistoryRoute: Hashable {
    case list
    case session(SessionRecord.ID)
    /// The iPad detail column before a session is chosen.
    case noSelection
}

enum SettingsRoute: Hashable {
    /// iPhone: every setting in one form.
    case form
    /// iPad content column: the categories, like the Settings app.
    case categories
    case page(SettingsPage)
}

/// One settings category or info page.
enum SettingsPage: Hashable {
    case sensor
    case breathing
    case biofeedback
    case health
    case appearance
    case privacy
    case aboutSensor
}

/// Finding and connecting the heart-rate sensor, presented as a sheet.
enum SensorRoute: Hashable {
    case connect
}

/// Support the Developer, presented as a sheet from the top of Settings.
enum SupportRoute: Hashable {
    case support
}

/// A live breathing session, presented as a full-screen cover.
enum SessionRoute: Hashable {
    case run(Technique.ID)
}

/// First-run onboarding, presented modally over the app.
enum OnboardingRoute: Hashable {
    case welcome
}
