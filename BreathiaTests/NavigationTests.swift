import Foundation
import Testing
@testable import Breathia

@MainActor
struct NavigationTests {
    private func navigator(regular: Bool) -> AppNavigator {
        let navigator = AppNavigator()
        navigator.windowWidthDidChange(isRegular: regular)
        return navigator
    }

    @Test func aPageOpenedInTheTabBarIsStillOpenInTheSplitView() {
        let navigator = navigator(regular: false)
        navigator.techniqueID = "box"
        #expect(navigator.pushedDetail(in: .breathe) == .technique("box"))

        navigator.windowWidthDidChange(isRegular: true)
        #expect(navigator.columnDetail(in: .breathe) == .technique("box"))
        #expect(navigator.selectedTechniqueID == "box")
    }

    @Test func theSplitViewShowsADefaultDetail() {
        let navigator = navigator(regular: true)
        #expect(navigator.columnDetail(in: .breathe) == .technique(TechniqueCatalog.defaultTechniqueID))
        #expect(navigator.columnDetail(in: .history) == .noSession)
        #expect(navigator.columnDetail(in: .settings) == .settings(.sensor))
        #expect(navigator.pushedDetail(in: .breathe) == nil)
    }

    @Test func goingBackInTheTabBarClosesThePage() {
        let navigator = navigator(regular: false)
        navigator.setPushedDetail(.settings(.health), in: .settings)
        #expect(navigator.settingsPage == .health)

        navigator.setPushedDetail(nil, in: .settings)
        #expect(navigator.settingsPage == nil)
    }

    @Test func listsKeepNoSelectionInTheTabBar() {
        let navigator = navigator(regular: false)
        navigator.techniqueID = "box"
        #expect(navigator.selectedTechniqueID == nil)
        #expect(navigator.selectedSettingsPage == nil)
    }

    @Test func startingASessionInTheTabBarReturnsBreatheToItsList() {
        let navigator = navigator(regular: false)
        navigator.techniqueID = "box"
        navigator.startSession(with: TechniqueCatalog.technique(withID: "box"))

        #expect(navigator.runningTechniqueID == "box")
        #expect(navigator.techniqueID == nil)

        navigator.endSession()
        #expect(navigator.runningTechniqueID == nil)
    }

    @Test func aFinishedSessionOpensInHistoryInTheSplitView() {
        let id = UUID()
        let split = navigator(regular: true)
        split.showHistory(with: id)
        #expect(split.selectedTab == .history)
        #expect(split.sessionID == id)

        let tabs = navigator(regular: false)
        tabs.showHistory(with: id)
        #expect(tabs.selectedTab == .history)
        #expect(tabs.sessionID == nil)
    }

    @Test func onboardingWaitsForTheLayout() {
        let navigator = AppNavigator()
        navigator.showOnboarding()
        #expect(navigator.onboarding == nil)

        navigator.windowWidthDidChange(isRegular: false)
        #if os(iOS)
        #expect(navigator.onboarding == .cover)
        #else
        #expect(navigator.onboarding == .sheet)
        #endif
    }

    @Test func aQuestionReturnsTheChosenAction() async {
        let navigator = AppNavigator()
        let dialog = AppDialog("rating.couldntOpenMail", actions: [AppDialog.Action("rating.ok", id: "yes")])
        async let choice = navigator.ask(dialog)
        while navigator.dialog == nil { await Task.yield() }

        navigator.answer("yes")
        // Closing the alert reports a dismissal too; the first answer counts.
        navigator.answer(nil)
        #expect(await choice == "yes")
        #expect(navigator.dialog == nil)
    }
}
