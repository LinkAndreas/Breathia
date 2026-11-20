import SwiftUI

/// A small label next to a highlighted point of a chart, such as the lowest value.
struct ChartPointLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
