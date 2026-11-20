import SwiftUI

/// Plays a breath in and a breath out with the chosen sound and volume.
struct CuePreviewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsLabel("settings.cuePreview", systemImage: "play.fill", tone: .cuePreview)
        }
        .foregroundStyle(.primary)
    }
}

#if DEBUG
#Preview {
    Form {
        CuePreviewButton {}
    }
}
#endif
