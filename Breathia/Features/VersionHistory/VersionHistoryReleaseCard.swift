import SwiftUI

/// A release on its card: its version and month, whether it's the one installed,
/// and its notes.
struct VersionHistoryReleaseCard: View {
    let release: VersionHistory.Release
    let isInstalled: Bool

    @Environment(AppIconStore.self) private var appIconStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("versionHistory.version \(release.version)")
                        .font(.headline)
                    Text(release.date, format: .dateTime.month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                if isInstalled {
                    Pill(
                        text: String(localized: "versionHistory.installed"),
                        tint: appIconStore.current.palette.accent ?? .accentColor,
                        size: .small
                    )
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(release.notes, id: \.key) { note in
                    VersionHistoryNoteRow(note: note)
                }
            }
        }
        .cardSurface(verticalPadding: 16)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    VersionHistoryReleaseCard(release: VersionHistory.releases[0], isInstalled: true)
        .padding()
        .background(Theme.Palette.background)
        .environment(AppIconStore.preview())
}
#endif
