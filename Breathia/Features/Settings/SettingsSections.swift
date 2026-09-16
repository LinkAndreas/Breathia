import SwiftUI

// Settings rows grouped by category. Each group is its own view so the iPhone
// form and the iPad category pages compose the same rows instead of duplicating them.

/// Sensor status that opens the sensor sheet (iPhone).
struct SensorSettingsRow: View {
    let action: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        Button(action: action) {
            LabeledContent {
                HStack(spacing: 6) {
                    StatusDot(isActive: monitor.isConnected)
                    Text(monitor.statusDetail)
                        .monospacedDigit()
                }
            } label: {
                SettingsLabel(
                    verbatim: monitor.sensorName,
                    systemImage: SettingsPage.sensor.systemImage,
                    color: SettingsPage.sensor.iconColor
                )
            }
        }
        .tint(.primary)
    }
}

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

struct BiofeedbackSettingsRows: View {
    static let footer: LocalizedStringKey = "settings.rmssdReflectsBeat"

    @Environment(SettingsStore.self) private var settingsStore

    var body: some View {
        @Bindable var store = settingsStore

        Picker(selection: $store.settings.hrvMetric) {
            ForEach(HRVMetric.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        } label: {
            SettingsLabel("settings.hrvMetric", systemImage: "waveform.path.ecg", color: .green)
        }
        Picker(selection: $store.settings.feedbackSensitivity) {
            ForEach(FeedbackSensitivity.allCases) { sensitivity in
                Text(sensitivity.title).tag(sensitivity)
            }
        } label: {
            SettingsLabel("settings.feedbackSensitivity", systemImage: "slider.horizontal.3", color: .teal)
        }
    }
}

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

struct AppearanceSettingsRows: View {
    @Environment(SettingsStore.self) private var settingsStore

    var body: some View {
        @Bindable var store = settingsStore

        #if os(macOS)
        // A labelled row, like System Settings, rather than a lone control.
        Picker(selection: $store.settings.appearance) {
            options
        } label: {
            SettingsLabel("settings.appearance", systemImage: SettingsPage.appearance.systemImage, color: SettingsPage.appearance.iconColor)
        }
        .pickerStyle(.segmented)
        #else
        Picker("settings.appearance", selection: $store.settings.appearance) {
            options
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        #endif
    }

    private var options: some View {
        ForEach(Appearance.allCases) { appearance in
            Text(appearance.title).tag(appearance)
        }
    }
}
