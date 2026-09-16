import SwiftUI

/// One settings page — the iPad detail column, or a page pushed on iPhone.
struct SettingsDetailView: View {
    let page: SettingsPage

    var body: some View {
        content
            .navigationTitle(page.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }

    @ViewBuilder
    private var content: some View {
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
            }

        case .privacy:
            PrivacyInfoView()

        case .aboutSensor:
            SensorInfoView()
        }
    }
}
