import SwiftUI

/// A settings group of its own, so the iPhone form and the iPad category pages
/// compose the same rows instead of duplicating them.
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
            SettingsLabel("settings.hrvMetric", systemImage: "waveform.path.ecg", tone: .hrvMetric)
        }
        Picker(selection: $store.settings.feedbackSensitivity) {
            ForEach(FeedbackSensitivity.allCases) { sensitivity in
                Text(sensitivity.title).tag(sensitivity)
            }
        } label: {
            SettingsLabel("settings.feedbackSensitivity", systemImage: "slider.horizontal.3", tone: .sensitivity)
        }
    }
}

#if DEBUG
#Preview {
    Form {
        BiofeedbackSettingsRows()
    }
    .environment(PreviewStores.settingsStore())
}
#endif
