import SwiftUI

/// iPhone settings: Support the Developer on top, then every category in one form.
struct SettingsView: View {
    let onShowSupport: () -> Void
    let onShowSensor: () -> Void
    let onOpenPage: (SettingsPage) -> Void
    let onShowOnboarding: () -> Void

    var body: some View {
        Form {
            Section {
                Button(action: onShowSupport) {
                    SupportDeveloperCard()
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

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

            Section {
                pageRow(.privacy)
                pageRow(.aboutSensor)
                Button(action: onShowOnboarding) {
                    SettingsLabel("settings.showOnboarding", systemImage: "sparkles", color: .purple)
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
        .navigationTitle("settings.title")
    }

    private func pageRow(_ page: SettingsPage) -> some View {
        Button {
            onOpenPage(page)
        } label: {
            HStack {
                SettingsLabel(verbatim: page.title, systemImage: page.systemImage, color: page.iconColor)
                Spacer()
                DisclosureChevron()
            }
        }
        .tint(.primary)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(onShowSupport: {}, onShowSensor: {}, onOpenPage: { _ in }, onShowOnboarding: {})
    }
    .environment(PreviewStores.heartRateMonitor())
    .environment(PreviewStores.settingsStore())
    .environment(PreviewStores.mindfulMinutes())
    .environment(SupportStore(service: PreviewSupportService()))
}
#endif
