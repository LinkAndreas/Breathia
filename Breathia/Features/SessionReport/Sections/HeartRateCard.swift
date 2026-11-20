import SwiftUI

/// The heart rate over the session: what happened in a sentence, the average,
/// lowest and highest value, and the full curve to explore.
struct HeartRateCard: View {
    let session: SessionRecord
    let stats: HeartRateStats

    private var points: [SessionTimeline.Point] { session.heartRatePoints }

    /// The heart rate averaged over two breaths: its course without the rise and
    /// fall of every breath. Only for the detailed timeline; an older session's
    /// short trace is smooth already.
    private var trend: [SessionTimeline.Point]? {
        guard let timeline = session.heartRateTimeline, timeline.values.count > 30 else { return nil }
        let breath = Double(max(4, session.technique.cycleDuration))
        return timeline.smoothed(over: 2 * breath).points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportCardTitle(title: Text("common.heartRate"))

            if let summary = session.heartRateSummary {
                Text(summary)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                ReportStat(label: "report.average", value: stats.average)
                if let lowest = points.map(\.value).min() {
                    ReportStat(label: "report.lowest", value: Int(lowest.rounded()))
                }
                if let highest = points.map(\.value).max() {
                    ReportStat(label: "report.highest", value: Int(highest.rounded()))
                }
            }

            if points.count > 1 {
                TimelineChart(
                    points: points,
                    trend: trend,
                    duration: session.duration,
                    tint: session.technique.tint,
                    format: ReportValueFormat.bpm
                )
                if trend != nil {
                    ChartLegend(tint: session.technique.tint)
                }
                #if os(macOS)
                ReportExplanation(text: "report.chart.pointToExplore")
                #else
                ReportExplanation(text: "report.chart.touchToExplore")
                #endif
            }
        }
        .cardSurface(verticalPadding: 16)
    }
}

#if DEBUG
#Preview {
    ScrollView {
        HeartRateCard(session: PreviewData.sessions[0], stats: PreviewData.sessions[0].heartRate!)
            .padding()
    }
}
#endif
