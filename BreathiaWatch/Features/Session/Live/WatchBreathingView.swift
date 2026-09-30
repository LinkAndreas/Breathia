import SwiftUI

/// The live session on Apple Watch, in two pages as in Workout: the breathing page,
/// which the session opens on, and Pause / End a swipe to the right. Keeping the
/// controls off the breathing page leaves the whole screen to the breath.
struct WatchBreathingView: View {
    let model: BreathingSessionModel

    enum Page {
        case controls, breathing
    }

    @State private var page = Page.breathing

    var body: some View {
        TabView(selection: $page) {
            WatchSessionControls(model: model) {
                // Back to the breath once the choice is made.
                withAnimation { page = .breathing }
            }
            .tag(Page.controls)
            WatchBreathingPage(model: model)
                .tag(Page.breathing)
        }
        // The cover's close button would end the session unrecorded, a tap away
        // from the breath; End is on the controls page.
        .toolbar(.hidden, for: .navigationBar)
        // The pages arrive in place rather than sliding in with the stage's animation.
        .transaction(value: page) { _ in }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.isPaused)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchBreathingView(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
    }
}
#endif
