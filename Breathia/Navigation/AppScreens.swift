import SwiftUI

/// What the screens need to be built: the navigator they report intents to, the
/// stores, and the flows. The views in `Navigation/Columns` and `Navigation/Screens`
/// take what each screen reads from here and hand it over — screens receive data and closures, plus only
/// the stores they read, so no store is in the environment where it isn't used.
final class AppScreens {
    let navigator: AppNavigator
    let sessionHistory: SessionHistory
    let settingsStore: SettingsStore
    let heartRateMonitor: HeartRateMonitor
    let mindfulMinutes: MindfulMinutesStore
    let appIconStore: AppIconStore
    /// Plays a cue sound for the Settings preview.
    let auditionCue: CueAuditioner
    let sessionFactory: BreathingSessionFactory
    let ratingFlow: RatingFlow
    /// The running session, kept while its screen is rebuilt.
    let sessionKeeper = SessionKeeper()

    init(
        navigator: AppNavigator,
        sessionHistory: SessionHistory,
        settingsStore: SettingsStore,
        heartRateMonitor: HeartRateMonitor,
        mindfulMinutes: MindfulMinutesStore,
        appIconStore: AppIconStore,
        sessionFactory: BreathingSessionFactory,
        ratingFlow: RatingFlow,
        auditionCue: CueAuditioner
    ) {
        self.navigator = navigator
        self.sessionHistory = sessionHistory
        self.settingsStore = settingsStore
        self.heartRateMonitor = heartRateMonitor
        self.mindfulMinutes = mindfulMinutes
        self.appIconStore = appIconStore
        self.sessionFactory = sessionFactory
        self.ratingFlow = ratingFlow
        self.auditionCue = auditionCue
    }
}
