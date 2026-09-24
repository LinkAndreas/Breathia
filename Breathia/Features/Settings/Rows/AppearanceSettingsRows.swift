import SwiftUI

/// A settings group of its own, so the iPhone form and the iPad category pages
/// compose the same rows instead of duplicating them.
struct AppearanceSettingsRows: View {
    @Environment(SettingsStore.self) private var settingsStore

    var body: some View {
        @Bindable var store = settingsStore

        #if os(macOS)
        // A labelled row, like System Settings, rather than a lone control.
        Picker(selection: $store.settings.appearance) {
            AppearanceOptions()
        } label: {
            SettingsLabel("settings.appearance", systemImage: SettingsPage.appearance.systemImage, color: SettingsPage.appearance.iconColor)
        }
        .pickerStyle(.segmented)
        #else
        Picker("settings.appearance", selection: $store.settings.appearance) {
            AppearanceOptions()
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        #endif
    }
}

#if DEBUG
#Preview {
    Form {
        AppearanceSettingsRows()
    }
    .environment(PreviewStores.settingsStore())
}
#endif
