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
                        stat("common.start", heartRate.start)
                        stat("watch.summary.avg", heartRate.average)
                        stat("common.end", heartRate.end)
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

    private func stat(_ label: LocalizedStringKey, _ value: Int) -> some View {
        VStack(spacing: 0) {
            Text(value, format: .number)
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
