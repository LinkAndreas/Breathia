import SwiftUI

/// The release's new features, marked as seen once they're on screen.
struct WhatsNewScreen: View {
    let screens: AppScreens

    var body: some View {
        let navigator = screens.navigator
        WhatsNewView(
            onTry: { navigator.tryNewFeature($0) },
            onDone: { navigator.isShowingWhatsNew = false },
            onSeen: { screens.settingsStore.markWhatsNewSeen(WhatsNew.version) }
        )
    }
}
