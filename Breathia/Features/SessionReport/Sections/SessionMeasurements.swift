import SwiftUI

/// The heart rate, its rise and fall with each breath, and HRV — or a note that
/// no sensor was connected.
struct SessionMeasurements: View {
    let session: SessionRecord

    var body: some View {
        VStack(spacing: 20) {
            if let heartRate = session.heartRate {
                HeartRateCard(session: session, stats: heartRate)
            } else {
                NoSensorDataCard()
            }

            if let swings = session.breathSwings, let summary = session.breathSwingSummary {
                BreathSwingCard(swings: swings, summary: summary, tint: session.technique.tint)
            }

            if let hrv = session.hrv {
                HRVCard(stats: hrv, timeline: session.hrvTimeline, duration: session.duration, tint: .green)
            }
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        SessionMeasurements(session: PreviewData.sessions[0])
            .padding()
    }
}
#endif
