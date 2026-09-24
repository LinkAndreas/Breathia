import SwiftUI

/// The appearances to choose from, each tagged for the appearance picker.
struct AppearanceOptions: View {
    var body: some View {
        ForEach(Appearance.allCases) { appearance in
            Text(appearance.title).tag(appearance)
        }
    }
}

#if DEBUG
#Preview {
    Picker("settings.appearance", selection: .constant(Appearance.allCases[0])) {
        AppearanceOptions()
    }
    .pickerStyle(.segmented)
    .padding()
}
#endif
