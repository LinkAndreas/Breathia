import SwiftUI

/// A settings group of its own, so the iPhone form and the iPad category pages
/// compose the same rows instead of duplicating them.
struct BreathingSettingsRows: View {
    static let footer: LocalizedStringKey = "settings.theseSettingsAlsoApply"

    @Environment(SettingsStore.self) private var settingsStore

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
        Toggle(isOn: $store.settings.countdownEnabled) {
            SettingsLabel("settings.countdown", systemImage: "timer", color: .blue)
        }
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
