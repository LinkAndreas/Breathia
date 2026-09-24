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
                ReportStat(label: "common.start", value: stats.start)
                ReportStat(label: "report.average", value: stats.average)
                ReportStat(label: "common.end", value: stats.end)
            }
            .padding(.bottom, 10)

            TrendSparkline(values: trace, tint: tint)
        }
        .cardSurface(verticalPadding: 14)
    }
}
