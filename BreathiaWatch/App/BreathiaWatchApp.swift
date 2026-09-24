import SwiftUI

@main
struct BreathiaWatchApp: App {
    @State private var dependencies = Self.makeDependencies()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if WatchScreenshotScreen.requested == .summary {
                WatchSessionSummaryView(session: WatchPreviewData.session, wasRecorded: true, onDone: {})
            } else {
                WatchRootView(router: dependencies.router, runner: dependencies.sessionRunner)
                    .task { dependencies.router.showForScreenshots() }
            }
            #else
            WatchRootView(router: dependencies.router, runner: dependencies.sessionRunner)
            #endif
        }
    }

    private static func makeDependencies() -> WatchDependencies {
        #if DEBUG
        if WatchScreenshotScreen.requested != nil {
            return .screenshots()
        }
        #endif
        return WatchDependencies()
    }
}
