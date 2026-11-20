import Charts
import SwiftUI

/// A measurement over a session: the curve, its average as a dashed line, its
/// lowest and highest points, and — while touched — the value at that moment.
///
/// With a `trend`, the trend is the bold curve and every reading a thin line
/// behind it, so the chart shows the overall course at a glance and the detail on
/// a closer look.
struct TimelineChart: View {
    let points: [SessionTimeline.Point]
    var trend: [SessionTimeline.Point]? = nil
    let duration: TimeInterval
    let tint: Color
    /// How a value reads in the chart, such as "63 BPM".
    let format: (Double) -> String

    @State private var selectedTime: Double?

    private var average: Double {
        points.isEmpty ? 0 : points.reduce(0) { $0 + $1.value } / Double(points.count)
    }

    private var lowest: SessionTimeline.Point? { points.min { $0.value < $1.value } }
    private var highest: SessionTimeline.Point? { points.max { $0.value < $1.value } }

    /// The values with some room above and below, so the labels fit.
    private var domain: ClosedRange<Double> {
        let low = lowest?.value ?? 0
        let high = highest?.value ?? 1
        let padding = max(2, (high - low) * 0.25)
        return (low - padding)...(high + padding)
    }

    private var selected: SessionTimeline.Point? {
        guard let selectedTime else { return nil }
        return points.min { abs($0.time - selectedTime) < abs($1.time - selectedTime) }
    }

    var body: some View {
        Chart {
            ForEach(trend ?? points) { point in
                AreaMark(
                    x: .value("report.chart.time", point.time),
                    yStart: .value("report.chart.value", domain.lowerBound),
                    yEnd: .value("report.chart.value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                )
            }

            if let trend {
                ForEach(points) { point in
                    LineMark(
                        x: .value("report.chart.time", point.time),
                        y: .value("report.chart.value", point.value),
                        series: .value("report.chart.series", "readings")
                    )
                    .foregroundStyle(tint.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, lineJoin: .round))
                    .accessibilityHidden(true)
                }
                ForEach(trend) { point in
                    LineMark(
                        x: .value("report.chart.time", point.time),
                        y: .value("report.chart.value", point.value),
                        series: .value("report.chart.series", "trend")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .accessibilityLabel(Formatters.clock(point.time))
                    .accessibilityValue(format(point.value))
                }
            } else {
                ForEach(points) { point in
                    LineMark(
                        x: .value("report.chart.time", point.time),
                        y: .value("report.chart.value", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .accessibilityLabel(Formatters.clock(point.time))
                    .accessibilityValue(format(point.value))
                }
            }

            RuleMark(y: .value("report.average", average))
                .foregroundStyle(Color.gray)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    ChartPointLabel(text: String(localized: "report.chart.averageValue \(Int(average.rounded()))"))
                }

            if selected == nil {
                if let lowest {
                    PointMark(x: .value("report.chart.time", lowest.time), y: .value("report.lowest", lowest.value))
                        .foregroundStyle(tint)
                        .symbolSize(36)
                        .annotation(position: .bottom) {
                            ChartPointLabel(text: format(lowest.value))
                        }
                }
                if let highest, highest != lowest {
                    PointMark(x: .value("report.chart.time", highest.time), y: .value("report.highest", highest.value))
                        .foregroundStyle(tint)
                        .symbolSize(36)
                        .annotation(position: .top) {
                            ChartPointLabel(text: format(highest.value))
                        }
                }
            }

            if let selected {
                RuleMark(x: .value("report.chart.time", selected.time))
                    .foregroundStyle(tint.opacity(0.35))
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        ChartCallout(title: Formatters.clock(selected.time), value: format(selected.value))
                    }
                PointMark(x: .value("report.chart.time", selected.time), y: .value("report.chart.value", selected.value))
                    .foregroundStyle(tint)
                    .symbolSize(70)
            }
        }
        .chartXScale(domain: 0...max(1, duration))
        .chartYScale(domain: domain)
        .chartXAxis {
            AxisMarks(values: ChartTimeScale.ticks(for: duration)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let seconds = value.as(Double.self) {
                        Text(verbatim: Formatters.clock(seconds))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
        }
        .chartXSelection(value: $selectedTime)
        // Room for the touched value's callout above the curve.
        .padding(.top, 24)
        .frame(height: 230)
    }
}

#if DEBUG
#Preview {
    TimelineChart(
        points: PreviewData.sessions[0].heartRateTimeline?.points ?? [],
        duration: PreviewData.sessions[0].duration,
        tint: .pink,
        format: { "\(Int($0.rounded())) BPM" }
    )
    .padding()
}
#endif
