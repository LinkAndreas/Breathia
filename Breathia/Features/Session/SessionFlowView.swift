import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Root of the full-screen session cover: countdown → session → results. The
/// session comes from `makeSession`, so this screen doesn't know which sensor,
/// cue player, or recorder it runs with.
///
/// The session belongs to `keeper`, not to this screen: when a layout change
/// rebuilds the cover, the new screen picks up the same session where it was.
struct SessionFlowView: View {
    /// Holds the session across rebuilds of this screen and ends it when it's left.
    let keeper: SessionKeeper
    /// Builds the session when the first screen of this presentation appears.
    let makeSession: () -> BreathingSessionModel
    /// Leaves without a result (cancelled during the countdown).
    let onCancel: () -> Void
    /// Leaves the results screen, passing the session if it was recorded (long
    /// enough to be kept in History).
    let onFinish: (SessionRecord?) -> Void

    @State private var model: BreathingSessionModel?
    #if os(macOS)
    /// Holds off display sleep while the session is open.
    @State private var displayAwake: NSObjectProtocol?
    #endif

    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()

            if let model {
                SessionStageView(model: model, onCancel: onCancel, onFinish: onFinish)
                    .animation(.smooth, value: model.stage)
            }
        }
        .onAppear(perform: startIfNeeded)
        // Away from the screen, cues and sensor readings stop: pause rather than let
        // the session and its Live Activity run on without the user.
        .sessionInterruptions(
            onInterrupt: { model?.interrupt() },
            onReturn: { model?.continueAfterInterruption() }
        )
        .onDisappear {
            keeper.detach()
            // A rebuilt screen that's already showing keeps the display awake.
            if !keeper.isOnScreen {
                keepDisplayAwake(false)
            }
        }
    }

    private func startIfNeeded() {
        keeper.attach()
        keepDisplayAwake(true)
        guard model == nil else { return }
        let model = keeper.session(make: makeSession)
        self.model = model
        // Starting is a no-op for a session that's already running.
        model.start()
    }

    /// Keeps the screen on while breathing.
    private func keepDisplayAwake(_ isOn: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = isOn
        #elseif os(macOS)
        if isOn, displayAwake == nil {
            displayAwake = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "Breathing session"
            )
        } else if !isOn, let displayAwake {
            ProcessInfo.processInfo.endActivity(displayAwake)
            self.displayAwake = nil
        }
        #endif
    }
}

#if DEBUG
#Preview {
    let factory = PreviewStores.sessionFactory()
    SessionFlowView(
        keeper: SessionKeeper(),
        makeSession: { factory.makeSession(for: TechniqueCatalog.all[1]) },
        onCancel: {},
        onFinish: { _ in }
    )
}
#endif
