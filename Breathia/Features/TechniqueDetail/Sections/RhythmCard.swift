import SwiftUI

/// The breathing rhythm at a glance: one tile per phase — the seconds large, the
/// phase below — and, after a divider, the session's length.
struct RhythmCard: View {
    let technique: Technique

    var body: some View {
        HStack(spacing: 0) {
            ForEach(technique.phases.indices, id: \.self) { index in
                let phase = technique.phases[index]
                MetricTile(
                    value: phase.seconds,
                    unit: "technique.secondsUnit",
                    caption: phase.kind.title,
                    tint: technique.tint
                )
            }
            Divider()
                .frame(height: 44)
                .padding(.horizontal, 4)
            MetricTile(
                value: technique.recommendedDuration / 60,
                unit: "technique.minutesUnit",
                caption: String(localized: "technique.detail.session"),
                tint: .primary
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.card))
    }
}
