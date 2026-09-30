import SwiftUI

struct HeartRateSummaryCard: View {
    let stats: HeartRateStats
    let trace: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("common.heartRate")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                ReportStat(label: "report.start", value: stats.start)
                ReportStat(label: "report.average", value: stats.average)
                ReportStat(label: "report.end", value: stats.end)
            }
            .padding(.bottom, 10)

            TrendSparkline(values: trace, tint: tint)
        }
        .cardSurface(verticalPadding: 14)
    }
}

#if DEBUG
#Preview {
    HeartRateSummaryCard(stats: PreviewData.sessions[0].heartRate!, trace: PreviewData.sessions[0].heartRateTrace, tint: PreviewData.sessions[0].technique.tint)
        .padding()
}
#endif
