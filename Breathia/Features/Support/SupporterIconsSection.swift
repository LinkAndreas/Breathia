import OSLog
import SwiftUI

/// The supporter app icons. Supporters pick the icon Breathia shows on the Home Screen or in
/// the Dock; everyone else sees the same icons locked, as a preview of what recurring support
/// includes.
struct SupporterIconsSection: View {
    let isUnlocked: Bool

    @Environment(AppIconStore.self) private var iconStore
    /// Goes up with every tap on a locked icon, to bounce its lock.
    @State private var lockedTapCount = 0
    /// Explains a locked icon: why it's locked, and how to unlock it.
    @State private var isExplainingLock = false

    private let logger = Logger(subsystem: "Breathia", category: "AppIcon")

    var body: some View {
        Section {
            Group {
                #if os(macOS)
                // A mouse can't swipe sideways, so on a Mac the icons wrap into rows.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 14, alignment: .top)], spacing: 14) {
                    SupporterIconTiles(isUnlocked: isUnlocked, lockedTapCount: lockedTapCount, onSelect: select)
                }
                .padding(.vertical, 6)
                #else
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        SupporterIconTiles(isUnlocked: isUnlocked, lockedTapCount: lockedTapCount, onSelect: select)
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                #endif
            }
            .sensoryFeedback(.selection, trigger: iconStore.current)
            .sensoryFeedback(.impact(weight: .light), trigger: lockedTapCount)
        } header: {
            Text("support.supporterAppIcons")
        } footer: {
            Text(isUnlocked ? "support.pickAnIcon" : "support.recurringSupportUnlocksIcons")
        }
        // No actions: the system adds its own OK.
        .alert("support.iconLocked.title", isPresented: $isExplainingLock) {} message: {
            Text("support.iconLocked.message")
        }
    }

    private func select(_ icon: SupporterIcon) {
        guard isUnlocked else {
            lockedTapCount += 1
            isExplainingLock = true
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
