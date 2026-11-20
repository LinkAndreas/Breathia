import SwiftUI

/// How much the heart rate rose and fell with each breath, breath by breath.
struct BreathSwingCard: View {
    let swings: [Double]
    let summary: BreathSwing.Summary
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportCardTitle(title: Text("report.breaths.title"))

            VStack(alignment: .leading, spacing: 4) {
                Text("report.breaths.summary \(Int(summary.average.rounded()))")
                if summary.grew {
                    Text("report.breaths.grew")
                }
            }
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                ReportStat(label: "report.average", value: Int(summary.average.rounded()))
                ReportStat(label: "report.largest", value: Int(summary.largest.rounded()))
                ReportStat(label: "report.breaths.count", value: summary.breaths)
            }

            BreathSwingChart(swings: swings, tint: tint)

            ReportExplanation(text: "report.breaths.explanation")
        }
        .cardSurface(verticalPadding: 16)
    }
}

#if DEBUG
#Preview {
    let session = PreviewData.sessions[0]
    ScrollView {
        BreathSwingCard(swings: session.breathSwings ?? [], summary: session.breathSwingSummary!, tint: session.technique.tint)
            .padding()
    }
}
#endif
