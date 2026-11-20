import SwiftUI

/// Chooses the sound that marks each phase of the breath.
struct CueSoundPicker: View {
    @Binding var selection: CueSound

    var body: some View {
        Picker(selection: $selection) {
            Section("settings.cueSound.group.struck") {
                ForEach(CueSound.struck) { sound in
                    Text(sound.title).tag(sound)
                }
            }
            Section("settings.cueSound.group.flowing") {
                ForEach(CueSound.flowing) { sound in
                    Text(sound.title).tag(sound)
                }
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
