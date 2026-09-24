import SwiftUI

/// iPad settings, content column: Support the Developer on top, then the
/// categories in grouped sections, like the Settings app. The selected category's
/// page fills the detail column; Support opens as a sheet.
struct SettingsCategoryList: View {
    @Binding var selection: SettingsPage?
    let onShowSupport: () -> Void
    let onShowOnboarding: () -> Void

    @Environment(MindfulMinutesStore.self) private var mindfulMinutes

    var body: some View {
        List(selection: $selection) {
            Section {
                // An action rather than a page, so it isn't selectable. It takes the
                // grouped section's rounded shape, as on iPhone.
                Button(action: onShowSupport) {
                    SupportDeveloperCard(isCompact: true)
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .padding(.vertical, 8)
                // As wide as the group cards below it.
                .padding(.horizontal, -8)
                .listRowSeparator(.hidden)
                #else
                .listRowInsets(EdgeInsets())
                #endif
                .listRowBackground(Color.clear)
            }
            Section {
                SettingsCategoryRow(page: .sensor, position: .single)
            }
            Section {
                SettingsCategoryRow(page: .breathing, position: .first)
                SettingsCategoryRow(page: .biofeedback, position: .middle)
                if mindfulMinutes.isAvailable {
                    SettingsCategoryRow(page: .health, position: .middle)
                }
                SettingsCategoryRow(page: .appearance, position: .last)
            }
            Section {
                SettingsCategoryRow(page: .privacy, position: .first)
                SettingsCategoryRow(page: .aboutSensor, position: .middle)
                // An action rather than a page, so it isn't selectable.
                Button(action: onShowOnboarding) {
                    SettingsLabel("settings.showOnboarding", systemImage: "sparkles", color: .purple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                #if os(macOS)
                .buttonStyle(.plain)
                .macListRow(in: .last)
                #endif
                .tint(.primary)
            } footer: {
                Text("settings.appNameAndVersion \(Bundle.main.shortVersion)")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        // Grouped like the pages in the detail column, so both columns match.
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        // The same surface as the other content columns; the sidebar material is
        // for the app's section list only.
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.background)
        #endif
        .navigationTitle("settings.title")
        #if os(macOS)
        // A Mac window has one title, taken from this column; the open page shows as
        // its subtitle, as the selected mailbox's details do in Mail.
        .navigationSubtitle(selection?.title ?? "")
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsCategoryList(selection: .constant(.breathing), onShowSupport: {}, onShowOnboarding: {})
    }
    .environment(PreviewStores.mindfulMinutes())
}
#endif
