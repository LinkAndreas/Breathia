import SwiftUI

struct HistoryListView: View {
    /// `true` on iPad, where rows stay selected and drive the detail column;
    /// `false` on iPhone, where tapping a row pushes its details.
    let usesSelection: Bool
    let selectedSessionID: SessionRecord.ID?
    let onOpen: (SessionRecord.ID) -> Void
    let onDeleted: (SessionRecord.ID) -> Void

    @Environment(SessionHistory.self) private var history

    var body: some View {
        list
            #if os(iOS)
            .listSectionSpacing(10)
            #else
            // The same surface as the other content columns.
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.background)
            #endif
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

    @ViewBuilder
    private var list: some View {
        if usesSelection {
            List(selection: selection) { rows }
        } else {
            List { rows }
        }
    }

    private var selection: Binding<SessionRecord.ID?> {
        Binding(
            get: { selectedSessionID },
            set: { id in
                if let id { onOpen(id) }
            }
        )
    }

    private var rows: some View {
        ForEach(history.sessions) { session in
            #if os(macOS)
            // Plain rows: a section per row clips the Mac's rounded selection highlight.
            deletableRow(for: session)
                .listRowSeparator(.hidden)
            #else
            Section {
                deletableRow(for: session)
            }
            #endif
        }
    }

    private func deletableRow(for session: SessionRecord) -> some View {
        row(for: session)
            .swipeActions {
                Button("common.delete", systemImage: "trash", role: .destructive) {
                    history.delete(session)
                    onDeleted(session.id)
                }
            }
    }

    @ViewBuilder
    private func row(for session: SessionRecord) -> some View {
        if usesSelection {
            HistoryRow(session: session)
                .tag(session.id)
        } else {
            Button {
                onOpen(session.id)
            } label: {
                HStack {
                    HistoryRow(session: session)
                    DisclosureChevron()
                }
            }
            .tint(.primary)
        }
    }
}

private struct HistoryRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 14) {
            TechniqueOrb(technique: session.technique, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(Formatters.relativeDay(session.date))
                        .font(.body.weight(.semibold))
                    if session.source == .watch {
                        Image(systemName: "applewatch")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("history.recordedOnAppleWatch")
                    }
                }
                Text(verbatim: "\(session.technique.name) · \(Formatters.clock(session.duration))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

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
        }
        // A Mac list row clips what it draws to its bounds; leave room for the orb's glow.
        #if os(macOS)
        .padding(.vertical, 10)
        .padding(.leading, 8)
        #else
        .padding(.vertical, 4)
        #endif
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
