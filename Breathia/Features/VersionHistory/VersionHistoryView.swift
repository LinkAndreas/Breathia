import SwiftUI

/// Every release with what it brought, newest first; the one running now is marked.
struct VersionHistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(VersionHistory.releases) { release in
                    VersionHistoryReleaseCard(release: release, isInstalled: release.isInstalled())
                }
            }
            .padding(20)
            .readableContentWidth()
        }
        .background(Theme.Palette.background)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsDetailView(page: .versionHistory)
    }
    .environment(AppIconStore.preview())
}
#endif
