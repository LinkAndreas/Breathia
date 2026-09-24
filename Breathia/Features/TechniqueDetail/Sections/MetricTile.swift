import SwiftUI

/// A large number with its unit, and a caption underneath.
struct MetricTile: View {
    let value: Int
    let unit: LocalizedStringKey
    let caption: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value, format: .number)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(caption)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    MetricTile(value: 4, unit: "technique.secondsUnit", caption: "Inhale", tint: .teal)
        .padding()
}
#endif
