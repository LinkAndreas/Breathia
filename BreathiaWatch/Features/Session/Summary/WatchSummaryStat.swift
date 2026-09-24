import SwiftUI

/// One of the summary's heart-rate figures: the number, what it is underneath.
struct WatchSummaryStat: View {
    let label: LocalizedStringKey
    let value: Int

    var body: some View {
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

#if DEBUG
#Preview {
    HStack {
        WatchSummaryStat(label: "common.start", value: 74)
        WatchSummaryStat(label: "watch.summary.avg", value: 68)
    }
}
#endif
