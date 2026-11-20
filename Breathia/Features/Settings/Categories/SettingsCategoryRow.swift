import SwiftUI

/// A selectable category in the settings list, on its group's card on the Mac.
struct SettingsCategoryRow: View {
    let page: SettingsPage
    /// Where the row sits in its group, which decides the corners of the Mac's card.
    let position: GroupPosition

    var body: some View {
        SettingsLabel(verbatim: page.title, systemImage: page.systemImage, tone: page.tone)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            #if os(macOS)
            .macListRow(in: position)
            #endif
            .tag(page)
    }
}

#if DEBUG
#Preview {
    List {
        SettingsCategoryRow(page: .breathing, position: .first)
        SettingsCategoryRow(page: .appearance, position: .last)
    }
}
#endif
