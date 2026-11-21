import SwiftUI

/// One thing a release brought, as a bulleted line.
struct VersionHistoryNoteRow: View {
    let note: LocalizedStringResource

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(verbatim: "•")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text(note)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview {
    VersionHistoryNoteRow(note: VersionHistory.releases[0].notes[0])
        .padding()
}
#endif
