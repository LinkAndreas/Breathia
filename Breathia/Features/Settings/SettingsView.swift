import SwiftUI

/// iPhone settings: every category in one form.
struct SettingsView: View {
    let onShowSensor: () -> Void
    let onOpenPage: (SettingsPage) -> Void
    let onShowOnboarding: () -> Void
    let onShowWhatsNew: () -> Void
    let onSendFeedback: () -> Void

    var body: some View {
        Form {
            Section("settings.sensor") {
                SensorSettingsRow(action: onShowSensor)
            }

            Section {
                BreathingSettingsRows()
            } header: {
                Text("settings.breathing")
            } footer: {
                Text(BreathingSettingsRows.footer)
            }

            Section {
                SoundSettingsRows()
            } header: {
                Text("settings.sound")
            } footer: {
                Text(SoundSettingsRows.footer)
            }

            Section {
                BiofeedbackSettingsRows()
            } header: {
                Text("settings.biofeedback")
            } footer: {
                Text(BiofeedbackSettingsRows.footer)
            }

            HealthSettingsSection()

            Section("settings.appearance") {
                AppearanceSettingsRows()
            }

            AppIconSection()

            HistorySettingsSection()

            FeedbackSettingsSection(onSendFeedback: onSendFeedback)

            Section {
                SettingsPageRow(page: .privacy) { onOpenPage(.privacy) }
                SettingsPageRow(page: .aboutSensor) { onOpenPage(.aboutSensor) }
                Button(action: onShowWhatsNew) {
                    SettingsLabel("settings.whatsNew", systemImage: "gift.fill", tone: .whatsNew)
                }
                .tint(.primary)
                Button(action: onShowOnboarding) {
                    SettingsLabel("settings.showOnboarding", systemImage: "sparkles", tone: .onboarding)
                }
                .tint(.primary)
            } header: {
                Text("settings.about")
            } footer: {
                Text("settings.appNameAndVersion \(Bundle.main.shortVersion)")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    // Keeps the last line well clear of the tab bar.
                    .padding(.bottom, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .background { AppIconWash() }
        .navigationTitle("settings.title")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(onShowSensor: {}, onOpenPage: { _ in }, onShowOnboarding: {}, onShowWhatsNew: {}, onSendFeedback: {})
    }
    .environment(PreviewStores.heartRateMonitor())
    .environment(PreviewStores.settingsStore())
    .environment(PreviewStores.mindfulMinutes())
    .environment(AppIconStore.preview())
    .environment(PreviewStores.sessionHistory())
}
#endif
