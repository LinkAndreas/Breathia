import SwiftUI

/// Heart rate variability: the session's average and trend, its curve when it
/// was recorded, and what HRV means.
struct HRVCard: View {
    let stats: HRVStats
    let timeline: SessionTimeline?
    let duration: TimeInterval
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportCardTitle(title: Text(verbatim: "HRV · \(stats.metric.title)"))

            HStack {
                Text("report.milliseconds \(Int(stats.average.rounded()))")
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
                Spacer()
                if let trend = stats.trend {
                    Text(trend.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trend.color, in: .capsule)
                }
            }

            if let timeline, timeline.values.count > 1 {
                TimelineChart(
                    points: timeline.points,
                    duration: duration,
                    tint: tint,
                    format: ReportValueFormat.milliseconds
                )
            }

            ReportExplanation(text: "report.hrv.explanation")
        }
        .cardSurface(verticalPadding: 16)
    }
}

#if DEBUG
#Preview {
    let session = PreviewData.sessions[0]
    ScrollView {
        HRVCard(stats: session.hrv!, timeline: session.hrvTimeline, duration: session.duration, tint: .green)
            .padding()
    }
}
#endif
