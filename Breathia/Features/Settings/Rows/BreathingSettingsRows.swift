import SwiftUI

/// A settings group of its own, so the iPhone form and the iPad category pages
/// compose the same rows instead of duplicating them.
struct BreathingSettingsRows: View {
    static let footer: LocalizedStringKey = "settings.theseSettingsAlsoApply"

    @Environment(SettingsStore.self) private var settingsStore
    @Environment(\.auditionCue) private var auditionCue

    var body: some View {
        @Bindable var store = settingsStore

        #if os(iOS)
        // Macs have no Taptic Engine to play breathing cues.
        Toggle(isOn: $store.settings.hapticsEnabled) {
            SettingsLabel("settings.hapticFeedback", systemImage: "hand.tap.fill", color: .orange)
        }
        #endif
        Toggle(isOn: $store.settings.soundEnabled) {
            SettingsLabel("settings.sound", systemImage: "speaker.wave.2.fill", color: .pink)
        }
        if store.settings.soundEnabled {
            CueSoundPicker(selection: $store.settings.cueSound)
                .onChange(of: store.settings.cueSound) { audition() }
            CueVolumeSlider(volume: $store.settings.cueVolume, onEditingEnded: audition)
            CuePreviewButton(action: audition)
        }
        Toggle(isOn: $store.settings.countdownEnabled) {
            SettingsLabel("settings.countdown", systemImage: "timer", color: .blue)
        }
    }

    private func audition() {
        auditionCue(settingsStore.settings.cueSound, volume: settingsStore.settings.cueVolume)
    }
}

#if DEBUG
#Preview {
    Form {
        BreathingSettingsRows()
    }
    .environment(PreviewStores.settingsStore())
}
#endif
