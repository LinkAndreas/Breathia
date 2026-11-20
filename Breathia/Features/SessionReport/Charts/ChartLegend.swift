import SwiftUI

/// What the two lines of a heart-rate chart are: the trend, bold, and every
/// reading, thin.
struct ChartLegend: View {
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            ChartLegendItem(title: "report.chart.trend", tint: tint, lineWidth: 3)
            ChartLegendItem(title: "report.chart.everySecond", tint: tint.opacity(0.45), lineWidth: 1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// One line of the legend: a short stroke in the line's style, and its name.
struct ChartLegendItem: View {
    let title: LocalizedStringKey
    let tint: Color
    let lineWidth: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(tint)
                .frame(width: 18, height: lineWidth)
                .accessibilityHidden(true)
            Text(title)
        }
    }
}

#if DEBUG
#Preview {
    ChartLegend(tint: .pink)
        .padding()
}
#endif
