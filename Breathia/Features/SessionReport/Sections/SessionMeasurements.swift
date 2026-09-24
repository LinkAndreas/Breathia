import SwiftUI

/// The heart rate and HRV cards, or a note that no sensor was connected.
struct SessionMeasurements: View {
    let session: SessionRecord

    var body: some View {
        VStack(spacing: 20) {
            if let heartRate = session.heartRate {
                HeartRateSummaryCard(stats: heartRate, trace: session.heartRateTrace, tint: session.technique.tint)
            } else {
                NoSensorDataCard()
            }

            if let hrv = session.hrv {
                HRVSummaryCard(stats: hrv)
            }
        }
    }
}
