import SwiftUI

/// The session's status bar with its progress under it.
struct SessionStatusHeader: View {
    let model: BreathingSessionModel

    var body: some View {
        VStack(spacing: 0) {
            SessionStatusBar(model: model)
                .padding(.horizontal, 24)
                // Clear of the display's rounded corner where the status bar runs down
                // the side and the safe area adds nothing at the top.
                .padding(.top, 16)

            SessionProgressBar(model: model)
                .padding(.horizontal, 24)
                .padding(.top, 14)
        }
    }
}
