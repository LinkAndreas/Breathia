import SwiftUI

struct LiveMetricCard: View {
    let value: String
    let label: LocalizedStringKey
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // One over the other: beside another card, they don't fit on one line.
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TrendSparkline(values: values, tint: tint, capacity: BreathingSessionModel.liveChartCapacity)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.row))
    }
}

#if DEBUG
#Preview {
    LiveMetricCard(value: "66 bpm avg", label: "common.heartRate", values: PreviewData.sessions[0].heartRateTrace, tint: .red)
        .padding()
}
#endif
