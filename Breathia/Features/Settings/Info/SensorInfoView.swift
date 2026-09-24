import SwiftUI

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
