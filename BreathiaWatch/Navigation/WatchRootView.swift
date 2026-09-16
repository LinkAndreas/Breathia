import SwiftUI

struct WatchRootView: View {
    let router: WatchRouter
    let runner: WatchSessionRunner

    /// A technique waiting to start until the user has seen why Health access is
    /// needed — the first session asks, not the app launch.
    @State private var awaitingHealthAccess: Technique?

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            WatchTechniqueListView()
                .navigationDestination(for: Technique.ID.self) { id in
                    let technique = TechniqueCatalog.technique(withID: id)
                    WatchTechniqueDetailView(technique: technique) {
                        start(technique)
                    }
                }
        }
        // Applies to every list and scroll view, including the session cover.
        .scrollIndicators(.hidden)
        .sheet(item: $awaitingHealthAccess) { technique in
            WatchHealthAccessView {
                Task {
                    await runner.requestAuthorization()
                    awaitingHealthAccess = nil
                    // Let the sheet close before the session cover comes up.
                    try? await Task.sleep(for: .milliseconds(400))
                    router.startSession(with: technique)
                }
            }
        }
        .fullScreenCover(item: $router.activeSession) { launch in
            WatchSessionFlowView(
                technique: launch.technique,
                runner: runner,
                onCancel: router.dismissSession,
                onDone: router.finishSession
            )
        }
    }

    private func start(_ technique: Technique) {
        if runner.needsAuthorization {
            awaitingHealthAccess = technique
        } else {
            router.startSession(with: technique)
        }
    }
}

#if DEBUG
#Preview {
    let dependencies = WatchDependencies(settingsRepository: InMemorySettingsRepository())
    WatchRootView(router: dependencies.router, runner: dependencies.sessionRunner)
}
#endif
