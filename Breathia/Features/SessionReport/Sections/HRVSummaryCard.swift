import SwiftUI

struct HRVSummaryCard: View {
    let stats: HRVStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stats.metric.title)
                .font(.footnote)
                .foregroundStyle(.secondary)

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
        }
        .cardSurface(verticalPadding: 14)
    }
}
