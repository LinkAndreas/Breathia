import SwiftUI

@main
struct BreathiaWatchApp: App {
    @State private var dependencies = WatchDependencies()

    var body: some Scene {
        WindowGroup {
            WatchRootView(router: dependencies.router, runner: dependencies.sessionRunner)
        }
    }
}
