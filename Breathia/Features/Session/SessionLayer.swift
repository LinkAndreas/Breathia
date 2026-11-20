#if os(iOS)
import NavigationKit
import SwiftUI

/// The running session over the whole app on iPhone and iPad.
///
/// Part of the window rather than a full-screen cover, so it turns with the window:
/// a cover presented on iPhone Duo's outer display stayed sideways once the phone
/// was unfolded. Its own navigation stack holds the countdown's close button.
struct SessionLayer: View {
    let techniqueID: Technique.ID
    let routes: AppRoutes
    let navigator: AppNavigator

    var body: some View {
        NavigationStack {
            routes.sessionScreen(techniqueID: techniqueID, nav: navigator.store.navigator)
        }
    }
}
#endif
