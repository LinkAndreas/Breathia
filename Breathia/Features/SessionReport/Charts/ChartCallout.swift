import SwiftUI

/// The value at the touched moment of a chart: when, and how much.
struct ChartCallout: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
    }
}

#if DEBUG
#Preview {
    ChartCallout(title: "4:12", value: "61 BPM")
        .padding()
}
#endif
