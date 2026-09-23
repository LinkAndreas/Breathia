import SwiftUI

struct HistoryListView: View {
    /// `true` on iPad and Mac, where the opened session stays highlighted next to
    /// the detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedSessionID: SessionRecord.ID?
    let onOpen: (SessionRecord.ID) -> Void
    let onDeleted: (SessionRecord.ID) -> Void

    @Environment(SessionHistory.self) private var history

    var body: some View {
        ScrollView {
            // Laid out like the techniques in Breathe: cards grouped under headers,
            // here by when the sessions happened, newest first.
            VStack(spacing: 0) {
                ForEach(SessionGroup.grouping(history.sessions)) { group in
                    CardListHeader {
                        Text(group.period.title())
                    }
                    LazyVStack(spacing: 10) {
                        ForEach(group.sessions) { session in
                            HistoryRow(
                                session: session,
                                period: group.period,
                                isSelected: usesSelection && session.id == selectedSessionID,
                                showsDisclosure: !usesSelection
                            ) {
                                onOpen(session.id)
                            }
                            .contextMenu {
                                Button("common.delete", systemImage: "trash", role: .destructive) {
                                    delete(session)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Theme.Palette.background)
        .overlay {
            if history.sessions.isEmpty {
                ContentUnavailableView(
                    "history.noSessionsYet",
                    systemImage: "clock",
                    description: Text("history.completedBreathingSessions")
                )
            }
        }
        .navigationTitle("history.title")
        #if os(macOS)
        // A Mac window has one title, taken from this column; the open session's
        // day shows as its subtitle, as the selected mailbox's details do in Mail.
        .navigationSubtitle(selectedSession.map { Formatters.relativeDay($0.date) } ?? "")
        #endif
    }

    #if os(macOS)
    private var selectedSession: SessionRecord? {
        selectedSessionID.flatMap { history.session(withID: $0) }
    }
    #endif

    private func delete(_ session: SessionRecord) {
        history.delete(session)
        onDeleted(session.id)
    }
}

/// A session as a card, like a technique in Breathe: the technique, when and how
/// long, and the average heart rate with the HRV trend.
private struct HistoryRow: View {
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
    NavigationStack {
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in })
    }
    .environment(PreviewStores.sessionHistory())
}
#endif

#if DEBUG
#Preview("Empty") {
    NavigationStack {
        HistoryListView(usesSelection: false, selectedSessionID: nil, onOpen: { _ in }, onDeleted: { _ in })
    }
    .environment(PreviewStores.sessionHistory(sessions: []))
}
#endif
