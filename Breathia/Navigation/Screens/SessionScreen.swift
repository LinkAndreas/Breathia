import SwiftUI

/// The session for a technique, from countdown to results, wired to the navigator,
/// History and the rating flow.
struct SessionScreen: View {
    let techniqueID: Technique.ID
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        SessionFlowView(
            keeper: screens.sessionKeeper,
            makeSession: {
                screens.sessionFactory.makeSession(for: TechniqueCatalog.technique(withID: techniqueID))
            },
            onCancel: {
                screens.sessionKeeper.release()
                navigator.endSession()
            },
            onFinish: { recordedSession in
                screens.sessionKeeper.release()
                navigator.endSession()
                if let recordedSession {
                    navigator.showHistory(with: recordedSession.id)
                    screens.ratingFlow.askIfAppropriate()
                } else {
                    navigator.showBreathe()
                }
            }
        )
    }
}
