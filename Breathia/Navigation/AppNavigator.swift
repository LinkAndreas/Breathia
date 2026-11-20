import SwiftUI

/// Where the user is in the app, and the intents that move them.
///
/// One state for both layouts: in a narrow window the sections are tabs and a
/// section's detail is pushed onto its stack; in a wide one they're a split view
/// with the detail beside the list. Each section keeps its detail here, so a page
/// opened in one layout is still open after the window changes width.
///
/// Knows destinations, not screens or stores: the views in `Navigation/Layout`
/// decide what each destination shows.
@Observable
final class AppNavigator {
    /// The section on screen: a tab, or a sidebar item.
    var selectedTab: AppTab = .breathe

    /// The technique opened in Breathe: pushed in the tab bar, beside the list in
    /// the split view, which shows the default technique while this is `nil`.
    var techniqueID: Technique.ID?

    /// The session opened in History. Without one, the split view's detail column
    /// asks the user to pick one.
    var sessionID: SessionRecord.ID?

    /// The settings page opened in Settings. The split view shows the sensor page
    /// while this is `nil`.
    var settingsPage: SettingsPage?

    /// Whether the sensor sheet is up.
    var isShowingSensor = false

    /// Whether the release's new features are shown.
    var isShowingWhatsNew = false

    /// How onboarding is presented, while it is.
    var onboarding: OnboardingPresentation?

    /// The technique of the session on screen; `nil` when no session runs.
    ///
    /// On iPhone and iPad, `AppRootView` lays the session over the whole app
    /// rather than presenting a full-screen cover: a cover presented on iPhone
    /// Duo's outer display came up sideways once the phone was unfolded. On the
    /// Mac it's a sheet.
    private(set) var runningTechniqueID: Technique.ID?

    /// Changes whenever the App Store rating dialog should be requested;
    /// `AppRootView` passes it on to the system.
    private(set) var reviewRequest = 0

    /// The question asked over the whole app, while it's waiting for an answer.
    private(set) var dialog: AppDialog?
    @ObservationIgnored private var dialogAnswer: CheckedContinuation<AppDialog.Action.ID?, Never>?

    /// Whether the window is wide enough for the split view; `nil` until the app is on
    /// screen. Reported by `AppRootView` from the horizontal size class.
    private(set) var isRegularWidth: Bool?

    /// Onboarding asked for before the app is on screen. Whether it covers the
    /// screen or comes up as a sheet depends on the layout, which isn't known yet.
    @ObservationIgnored private var isOnboardingPending = false

    /// Whether the split view is on screen, where lists keep a selection.
    var usesSplitLayout: Bool { isRegularWidth == true }

    func windowWidthDidChange(isRegular: Bool) {
        isRegularWidth = isRegular
        if isOnboardingPending {
            isOnboardingPending = false
            showOnboarding()
        }
    }

    // MARK: Selection

    /// The technique highlighted in the list: only in the split view, where the
    /// detail column always shows one.
    var selectedTechniqueID: Technique.ID? {
        usesSplitLayout ? techniqueID ?? TechniqueCatalog.defaultTechniqueID : nil
    }

    var selectedSessionID: SessionRecord.ID? {
        usesSplitLayout ? sessionID : nil
    }

    var selectedSettingsPage: SettingsPage? {
        usesSplitLayout ? settingsPage ?? .sensor : nil
    }

    /// Leaves a session page that no longer applies (e.g. a deleted session).
    func closeHistorySession() {
        sessionID = nil
    }

    // MARK: Sessions

    /// Starts a session over the app. In the tab bar, Breathe returns to its list
    /// behind the session, so the technique page isn't still open afterwards.
    func startSession(with technique: Technique) {
        if !usesSplitLayout {
            techniqueID = nil
        }
        runningTechniqueID = technique.id
    }

    /// Takes the session off screen.
    func endSession() {
        runningTechniqueID = nil
    }

    // MARK: Modals

    func showSensor() {
        isShowingSensor = true
    }

    /// Presents onboarding — on first launch, and again from Settings. Full screen
    /// over the tab bar; a form sheet over the split view and on the Mac.
    func showOnboarding() {
        guard let isRegularWidth else {
            isOnboardingPending = true
            return
        }
        #if os(iOS)
        onboarding = isRegularWidth ? .sheet : .cover
        #else
        onboarding = .sheet
        #endif
    }

    func closeOnboarding() {
        onboarding = nil
    }

    /// Shows the release's new features — once after an update, and from Settings.
    func showWhatsNew() {
        isShowingWhatsNew = true
    }

    /// Closes the new features and opens where one of them can be tried.
    func tryNewFeature(_ destination: WhatsNew.Feature.Destination) {
        isShowingWhatsNew = false
        switch destination {
        case .soundSettings:
            selectedTab = .settings
            settingsPage = .sound
        }
    }

    /// Asks a question over the whole app and returns the chosen action's ID, or
    /// `nil` if it was dismissed.
    func ask(_ dialog: AppDialog) async -> AppDialog.Action.ID? {
        answer(nil)
        return await withCheckedContinuation { continuation in
            dialogAnswer = continuation
            self.dialog = dialog
        }
    }

    /// Answers the open question with `actionID`; `nil` when it was dismissed.
    /// Only the first answer counts.
    func answer(_ actionID: AppDialog.Action.ID?) {
        dialog = nil
        dialogAnswer?.resume(returning: actionID)
        dialogAnswer = nil
    }

    // MARK: Rating

    /// Whether nothing is in the user's way: no session, sheet or question. The
    /// rating dialog only comes then, never during a task.
    var isCalm: Bool {
        runningTechniqueID == nil && !isShowingSensor && onboarding == nil && !isShowingWhatsNew && dialog == nil
    }

    func requestReview() {
        reviewRequest += 1
    }

    // MARK: Sections

    /// Returns to Breathe, ready for the next session.
    func showBreathe() {
        selectedTab = .breathe
    }

    /// Shows History after a session: the list with the new session on top in the
    /// tab bar; in the split view, that session also opens in the detail column.
    func showHistory(with sessionID: SessionRecord.ID) {
        selectedTab = .history
        self.sessionID = usesSplitLayout ? sessionID : nil
    }
}

/// How onboarding comes up.
enum OnboardingPresentation {
    /// Over the whole screen, in the tab bar.
    case cover
    /// A form sheet, over the split view and on the Mac.
    case sheet
}

#if DEBUG
extension AppNavigator {
    /// Opens the screen asked for with `-screenshot`, once the layout is on screen.
    func showForScreenshots() async {
        guard let screen = ScreenshotScreen.requested else { return }
        try? await Task.sleep(for: .seconds(1))
        let session = PreviewData.sessions[0]
        switch screen {
        case .breathe:
            showBreathe()
        case .technique:
            selectedTab = .breathe
            techniqueID = ScreenshotScreen.techniqueID
        case .session:
            selectedTab = .breathe
            if usesSplitLayout {
                techniqueID = ScreenshotScreen.techniqueID
            }
            runningTechniqueID = ScreenshotScreen.techniqueID
        case .history:
            showHistory(with: session.id)
        case .historyDetail:
            selectedTab = .history
            sessionID = session.id
        case .settings:
            selectedTab = .settings
            if usesSplitLayout {
                settingsPage = .breathing
            }
        case .sensor:
            showSensor()
        }
    }
}
#endif
