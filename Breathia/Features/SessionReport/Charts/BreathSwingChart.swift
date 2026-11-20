import Charts
import SwiftUI

/// The heart rate's rise and fall within each breath, one bar per breath, with the
/// average as a dashed line. Touching a bar shows its breath and swing.
struct BreathSwingChart: View {
    let swings: [Double]
    let tint: Color

    @State private var selectedBreath: Int?

    private var average: Double {
        swings.isEmpty ? 0 : swings.reduce(0, +) / Double(swings.count)
    }

    var body: some View {
        Chart {
            ForEach(Array(swings.enumerated()), id: \.offset) { index, swing in
                BarMark(
                    x: .value("report.breaths.axis", index + 1),
                    y: .value("report.breaths.swing", swing)
                )
                .foregroundStyle(tint.gradient)
                .opacity(selectedBreath == nil || selectedBreath == index + 1 ? 1 : 0.35)
                .cornerRadius(2)
                .accessibilityLabel(Text("report.breaths.breath \(index + 1)"))
                .accessibilityValue(Text("common.bpm \(Int(swing.rounded()))"))
            }

            RuleMark(y: .value("report.average", average))
                .foregroundStyle(Color.gray)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    ChartPointLabel(text: String(localized: "report.chart.averageValue \(Int(average.rounded()))"))
                }

            if let selectedBreath, swings.indices.contains(selectedBreath - 1) {
                RuleMark(x: .value("report.breaths.axis", selectedBreath))
                    .foregroundStyle(.clear)
                    .annotation(
                        position: .top,
                        spacing: 4,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        ChartCallout(
                            title: String(localized: "report.breaths.breath \(selectedBreath)"),
                            value: String(localized: "common.bpm \(Int(swings[selectedBreath - 1].rounded()))")
                        )
                    }
            }
        }
        .chartXScale(domain: 0.5...(Double(swings.count) + 0.5))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisValueLabel {
                    if let breath = value.as(Int.self) {
                        Text(breath, format: .number)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
        }
        .chartXSelection(value: $selectedBreath)
        .padding(.top, 36)
        .frame(height: 190)
    }
}

#if DEBUG
#Preview {
    BreathSwingChart(swings: PreviewData.sessions[0].breathSwings ?? [], tint: .pink)
        .padding()
}
#endif
