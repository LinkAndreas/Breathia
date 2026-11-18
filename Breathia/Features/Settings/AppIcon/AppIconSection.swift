import OSLog
import SwiftUI

/// The app icon picker: the icon Breathia shows on the Home Screen or in the Dock, which the
/// app also takes its accent color and background wash from. Shows nothing where the icon
/// can't be changed.
struct AppIconSection: View {
    @Environment(AppIconStore.self) private var iconStore

    private let logger = Logger(subsystem: "Breathia", category: "AppIcon")

    var body: some View {
        if iconStore.canChangeIcon {
            Section {
                Group {
                    #if os(macOS)
                    // A mouse can't swipe sideways, so on a Mac the icons wrap into rows.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 14, alignment: .top)], spacing: 14) {
                        AppIconTiles(onSelect: select)
                    }
                    .padding(.vertical, 6)
                    #else
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            AppIconTiles(onSelect: select)
                        }
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                    #endif
                }
                .sensoryFeedback(.selection, trigger: iconStore.current)
            } header: {
                Text("settings.appIcon")
            } footer: {
                #if os(macOS)
                Text("settings.appIcon.footerMac")
                #else
                Text("settings.appIcon.footer")
                #endif
            }
        }
    }

    private func select(_ icon: AppIconVariant) {
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
#Preview {
    Form {
        AppIconSection()
    }
    .environment(AppIconStore.preview(.lagoon))
}
#endif
