import SwiftUI

/// The sound cues: whether they play, which sound, how loud, and a sample.
/// A settings group of its own, so the iPhone form and the iPad category page
/// compose the same rows.
struct SoundSettingsRows: View {
    static let footer: LocalizedStringKey = "settings.sound.footer"

    @Environment(SettingsStore.self) private var settingsStore
    @Environment(\.auditionCue) private var auditionCue

    var body: some View {
        @Bindable var store = settingsStore

        Toggle(isOn: $store.settings.soundEnabled) {
            SettingsLabel("settings.soundCues", systemImage: "speaker.wave.2.fill", color: .pink)
        }
        if store.settings.soundEnabled {
            CueSoundPicker(selection: $store.settings.cueSound)
                .onChange(of: store.settings.cueSound) { audition() }
            CueVolumeSlider(volume: $store.settings.cueVolume, onEditingEnded: audition)
            CuePreviewButton(action: audition)
        }
    }

    private func audition() {
        auditionCue(settingsStore.settings.cueSound, volume: settingsStore.settings.cueVolume)
    }
}

#if DEBUG
#Preview {
    Form {
        SoundSettingsRows()
    }
    .environment(PreviewStores.settingsStore())
}
#endif
