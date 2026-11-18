import SwiftUI

/// What a settings page shows: its form, or the view it's made of.
struct SettingsPageContent: View {
    let page: SettingsPage

    var body: some View {
        switch page {
        case .sensor:
            // Don't start a Bluetooth scan just because Settings opened on this page.
            SensorConnectionView(scansOnAppear: false)

        case .breathing:
            Form {
                Section {
                    BreathingSettingsRows()
                } footer: {
                    #if os(iOS)
                    Text(BreathingSettingsRows.footer)
                    #endif
                }
            }

        case .biofeedback:
            Form {
                Section {
                    BiofeedbackSettingsRows()
                } footer: {
                    Text(BiofeedbackSettingsRows.footer)
                }
            }

        case .health:
            Form {
                HealthSettingsSection()
            }

        case .appearance:
            Form {
                Section {
                    AppearanceSettingsRows()
                }
                AppIconSection()
            }

        case .privacy:
            PrivacyInfoView()

        case .aboutSensor:
            SensorInfoView()
        }
    }
}

#if DEBUG
#Preview {
    SettingsPageContent(page: .biofeedback)
        .environment(PreviewStores.settingsStore())
}
#endif
