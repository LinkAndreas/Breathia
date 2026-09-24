import Charts
import SwiftUI

/// A compact, axis-less area chart for heart-rate and HRV traces.
struct TrendSparkline: View {
    let values: [Double]
    let tint: Color
    /// When set, the x-axis is fixed to this many samples so a live chart fills
    /// from the left instead of stretching its first few points across the width.
    var capacity: Int?
    var height: CGFloat = 44

    var body: some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                AreaMark(
                    x: .value("trend.sample", index),
                    yStart: .value("trend.floor", yDomain.lowerBound),
                    yEnd: .value("trend.value", value)
                )
                .foregroundStyle(
                    LinearGradient(colors: [tint.opacity(0.3), tint.opacity(0)], startPoint: .top, endPoint: .bottom)
                )
                .interpolationMethod(.catmullRom)

                LineMark(x: .value("trend.sample", index), y: .value("trend.value", value))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXScale(domain: 0...max(1, (capacity ?? values.count) - 1))
        .chartYScale(domain: yDomain)
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private var yDomain: ClosedRange<Double> {
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max(1, (high - low) * 0.2)
        return (low - padding)...(high + padding)
    }
}
