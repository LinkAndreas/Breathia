import SwiftUI

/// A settings row title with its `SettingsIcon`.
struct SettingsLabel: View {
    private let title: Text
    private let systemImage: String
    private let tone: SettingsTone

    init(_ title: LocalizedStringKey, systemImage: String, tone: SettingsTone) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.tone = tone
    }

    init(verbatim title: String, systemImage: String, tone: SettingsTone) {
        self.title = Text(verbatim: title)
        self.systemImage = systemImage
        self.tone = tone
    }

    var body: some View {
        #if os(macOS)
        // Lists on the Mac don't space a custom label icon from its title.
        HStack(spacing: 8) {
            SettingsIcon(systemImage: systemImage, tone: tone)
            title
        }
        #else
        Label {
            title
        } icon: {
            SettingsIcon(systemImage: systemImage, tone: tone)
        }
        #endif
    }
}

#if DEBUG
#Preview {
    List {
        SettingsLabel("settings.sound", systemImage: "speaker.wave.2.fill", tone: .soundCues)
        SettingsLabel(verbatim: "Polar H10", systemImage: "antenna.radiowaves.left.and.right", tone: .heart)
    }
}
#endif
