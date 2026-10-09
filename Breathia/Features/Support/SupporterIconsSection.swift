import OSLog
import SwiftUI

/// The supporter app icons. Supporters pick the icon Breathia shows on the Home Screen;
/// everyone else sees the same icons locked, as a preview of what recurring support includes.
struct SupporterIconsSection: View {
    let isUnlocked: Bool

    @Environment(AppIconStore.self) private var iconStore
    /// Goes up with every tap on a locked icon, to bounce its lock.
    @State private var lockedTapCount = 0

    private let logger = Logger(subsystem: "Breathia", category: "AppIcon")

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(SupporterIcon.allCases) { icon in
                        SupporterIconTile(
                            icon: icon,
                            isSelected: icon == iconStore.current,
                            isLocked: !isUnlocked && icon != .classic,
                            lockedTapCount: lockedTapCount
                        ) {
                            select(icon)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: iconStore.current)
            .sensoryFeedback(.impact(weight: .light), trigger: lockedTapCount)
        } header: {
            Text("support.supporterAppIcons")
        } footer: {
            Text(isUnlocked ? "support.pickAnIcon" : "support.recurringSupportUnlocksIcons")
        }
    }

    private func select(_ icon: SupporterIcon) {
        guard isUnlocked else {
            lockedTapCount += 1
            return
        }

        Task {
            do {
                try await iconStore.select(icon)
            } catch {
                logger.error("Setting the app icon to \(icon.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
}

#if DEBUG
#Preview("Locked") {
    Form {
        SupporterIconsSection(isUnlocked: false)
    }
    .environment(AppIconStore.preview())
}

#Preview("Unlocked") {
    Form {
        SupporterIconsSection(isUnlocked: true)
    }
    .environment(AppIconStore.preview(.lagoon))
}
#endif
