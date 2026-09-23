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
                row(.sensor, in: .single)
            }
            Section {
                row(.breathing, in: .first)
                row(.biofeedback, in: .middle)
                if mindfulMinutes.isAvailable {
                    row(.health, in: .middle)
                }
                row(.appearance, in: .last)
            }
            Section {
                row(.privacy, in: .first)
                row(.aboutSensor, in: .middle)
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

    private func row(_ page: SettingsPage, in position: GroupPosition) -> some View {
        SettingsLabel(verbatim: page.title, systemImage: page.systemImage, color: page.iconColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            #if os(macOS)
            .macListRow(in: position)
            #endif
            .tag(page)
    }
}

extension SettingsPage {
    var title: String {
        switch self {
        case .sensor: String(localized: "common.heartRateSensor")
        case .breathing: String(localized: "settings.breathing")
        case .biofeedback: String(localized: "settings.biofeedback")
        case .health: String(localized: "settings.appleHealth")
        case .appearance: String(localized: "settings.appearance")
        case .privacy: String(localized: "common.privacy")
        case .aboutSensor: String(localized: "common.aboutBluetoothPolarH10")
        }
    }

    var systemImage: String {
        switch self {
        case .sensor: "antenna.radiowaves.left.and.right"
        case .breathing: "wind"
        case .biofeedback: "waveform.path.ecg"
        case .health: "heart.fill"
        case .appearance: "circle.lefthalf.filled"
        case .privacy: "hand.raised.fill"
        case .aboutSensor: "info"
        }
    }

    var iconColor: Color {
        switch self {
        case .sensor: .red
        case .breathing: .teal
        case .biofeedback: .green
        case .health: .pink
        case .appearance: .indigo
        case .privacy: .blue
        case .aboutSensor: .gray
        }
    }
}

/// Where a row sits in its group, which decides which corners of the group's card it rounds.
private enum GroupPosition {
    case single, first, middle, last
}

#if os(macOS)
private extension View {
    /// A roomy row on its group's card. Mac lists have no grouped style, so each row
    /// draws its slice of the card — rounded at the group's first and last row — and
    /// the groups read as separate blocks, like the grouped forms beside them.
    func macListRow(in position: GroupPosition) -> some View {
        let radius: CGFloat = 10
        let roundsTop = position == .single || position == .first
        let roundsBottom = position == .single || position == .last
        return padding(.vertical, 5)
            .padding(.horizontal, 6)
            .listRowSeparator(.hidden)
            .listRowBackground(
                UnevenRoundedRectangle(
                    topLeadingRadius: roundsTop ? radius : 0,
                    bottomLeadingRadius: roundsBottom ? radius : 0,
                    bottomTrailingRadius: roundsBottom ? radius : 0,
                    topTrailingRadius: roundsTop ? radius : 0,
                    style: .continuous
                )
                .fill(Theme.Palette.elevated)
                // The same inset as the list's selection highlight, so it fills the card.
                .padding(.horizontal, 10)
            )
    }
}
#endif
