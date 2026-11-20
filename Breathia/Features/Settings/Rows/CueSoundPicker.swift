import SwiftUI

/// Chooses the sound that marks each phase of the breath.
struct CueSoundPicker: View {
    @Binding var selection: CueSound

    var body: some View {
        Picker(selection: $selection) {
            ForEach(CueSound.allCases) { sound in
                Text(sound.title).tag(sound)
            }
        } label: {
            SettingsLabel("settings.cueSound", systemImage: "music.note", color: .purple)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var sound = CueSound.bowl
    Form {
        CueSoundPicker(selection: $sound)
    }
}
#endif
