import SwiftUI

/// The Apple Health section. Hidden on devices without Health. Turning the toggle
/// on asks for permission; if access was denied, the footer says where to allow it.
struct HealthSettingsSection: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(MindfulMinutesStore.self) private var mindfulMinutes

    var body: some View {
        if mindfulMinutes.isAvailable {
            Section {
                Toggle(isOn: savesMindfulMinutes) {
                    SettingsLabel("common.saveMindfulMinutes", systemImage: "heart.fill", color: .pink)
                }
            } header: {
                Text("settings.appleHealth")
            } footer: {
                if mindfulMinutes.isDenied && settingsStore.settings.savesMindfulMinutes {
                    Text("settings.breathiaIsntAllowed")
                } else {
                    Text("settings.eachCompletedBreathingSession")
                }
            }
            .onAppear(perform: mindfulMinutes.refreshAuthorizationStatus)
        }
    }

    private var savesMindfulMinutes: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.savesMindfulMinutes },
            set: { isOn in
                settingsStore.settings.savesMindfulMinutes = isOn
                if isOn {
                    Task { await mindfulMinutes.requestAuthorization() }
                }
            }
        )
    }
}

#if DEBUG
#Preview {
    Form {
        HealthSettingsSection()
    }
    .environment(PreviewStores.settingsStore())
    .environment(PreviewStores.mindfulMinutes())
}
#endif
