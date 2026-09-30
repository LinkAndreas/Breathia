import SwiftUI

struct WatchSessionSummaryView: View {
    let session: SessionRecord
    let wasRecorded: Bool
    let onDone: () -> Void

    private var tint: Color { session.technique.tint }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(tint, in: .circle)
                    .accessibilityHidden(true)

                Text("common.sessionComplete")
                    .font(.headline)

                Text(verbatim: "\(session.technique.name) · \(Formatters.clock(session.duration))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let heartRate = session.heartRate {
                    HStack {
                        WatchSummaryStat(label: "report.start", value: heartRate.start)
                        WatchSummaryStat(label: "watch.summary.avg", value: heartRate.average)
                        WatchSummaryStat(label: "report.end", value: heartRate.end)
                    }
                    .padding(.vertical, 4)
                }

                if wasRecorded {
                    Label("watch.summary.syncsToIPhoneHistory", systemImage: "iphone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button("common.done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
                    .padding(.top, 4)
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchSessionSummaryView(session: WatchPreviewData.session, wasRecorded: true, onDone: {})
}
#endif
