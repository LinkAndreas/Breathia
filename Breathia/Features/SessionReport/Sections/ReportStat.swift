import SwiftUI

/// One of a card's figures: the number large, what it is underneath.
struct ReportStat: View {
    let label: LocalizedStringKey
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
