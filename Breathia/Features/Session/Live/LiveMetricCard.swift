import SwiftUI

struct LiveMetricCard: View {
    let value: String
    let label: LocalizedStringKey
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
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
