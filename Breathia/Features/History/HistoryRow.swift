import SwiftUI

/// A session as a card, like a technique in Breathe: the technique, when and how
/// long, and the average heart rate with the HRV trend.
struct HistoryRow: View {
    let session: SessionRecord
    /// The section the row sits in, which already says the day where it can.
    let period: SessionPeriod
    let isSelected: Bool
    let showsDisclosure: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                TechniqueOrb(technique: session.technique, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.technique.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(verbatim: "\(when) · \(Formatters.clock(session.duration))")
                        if session.source == .watch {
                            Image(systemName: "applewatch")
                                .accessibilityLabel("history.recordedOnAppleWatch")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.heartRate.map { String(localized: "common.bpm \($0.average)") } ?? String(localized: "history.noSensor"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(session.hasSensorData ? .primary : .secondary)
                    if let trend = session.hrv?.trend {
                        Text(trend.shortLabel)
                            .font(.caption)
                            .foregroundStyle(trend == .increasing ? Color.green : Color.secondary)
                    }
                }

                if showsDisclosure {
                    DisclosureChevron()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.row))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.row)
                    .strokeBorder(isSelected ? session.technique.tint : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.plain)
        #if os(iOS)
        // Highlights the card under the pointer on iPad.
        .hoverEffect(.highlight)
        #endif
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// When the session started: the time where the section names the day, the
    /// weekday within the last week, the date before that.
    private var when: String {
        switch period {
        case .today, .yesterday:
            session.date.formatted(date: .omitted, time: .shortened)
        case .previous7Days:
            session.date.formatted(.dateTime.weekday(.wide).hour().minute())
        case .previous30Days, .month:
            session.date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 10) {
        HistoryRow(session: PreviewData.sessions[0], period: .yesterday, isSelected: false, showsDisclosure: true) {}
        HistoryRow(session: PreviewData.sessions[4], period: .previous30Days, isSelected: true, showsDisclosure: false) {}
    }
    .padding()
}
#endif
