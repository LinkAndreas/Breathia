import SwiftUI

struct PrivacyInfoView: View {
    var body: some View {
        InfoPage(title: "common.privacy", sections: [
            .init(heading: "settings.info.yourDataStays", body: "settings.info.heartRateReadingsHRV"),
            .init(heading: "settings.info.bluetooth", body: "settings.info.bluetoothIsUsedSolely"),
            .init(heading: "settings.info.deletingData", body: "settings.info.swipeASession"),
        ])
    }
}

struct SensorInfoView: View {
    var body: some View {
        InfoPage(title: "common.aboutBluetoothPolarH10", sections: [
            .init(heading: "settings.info.wearingTheStrap", body: "settings.info.moistenTheElectrodeAreas"),
            .init(heading: "settings.info.connecting", body: "settings.info.openTheSensorSheet"),
            .init(heading: "settings.info.heartRateHRV", body: "settings.info.theSensorReportsEvery"),
            .init(heading: "settings.info.notMedicalAdvice", body: "settings.info.breathia"),
        ])
    }
}

private struct InfoPage: View {
    struct Section {
        let heading: LocalizedStringKey
        let body: LocalizedStringKey
    }

    let title: LocalizedStringKey
    let sections: [Section]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(sections.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sections[index].heading)
                            .font(.headline)
                        Text(sections[index].body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .readableContentWidth()
        }
        .background(Theme.Palette.background)
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
