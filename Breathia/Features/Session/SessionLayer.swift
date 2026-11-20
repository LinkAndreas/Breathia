import SwiftUI

/// The running session over the whole app: a layer in the window on iPhone and
/// iPad, a sheet on the Mac.
///
/// On iPhone and iPad it's part of the window rather than a full-screen cover, so
/// it turns with the window: a cover presented on iPhone Duo's outer display
/// stayed sideways once the phone was unfolded. Its own navigation stack holds the
/// countdown's close button.
struct SessionLayer: View {
    let techniqueID: Technique.ID
    let screens: AppScreens

    var body: some View {
        NavigationStack {
            screens.sessionScreen(techniqueID: techniqueID)
        }
        #if os(macOS)
        // Large enough for the breathing circle.
        .frame(minWidth: 560, idealWidth: 720, minHeight: 680, idealHeight: 760)
        #endif
    }
}
