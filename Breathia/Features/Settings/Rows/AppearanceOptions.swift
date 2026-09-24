import SwiftUI

/// The appearances to choose from, each tagged for the appearance picker.
struct AppearanceOptions: View {
    var body: some View {
        ForEach(Appearance.allCases) { appearance in
            Text(appearance.title).tag(appearance)
        }
    }
}
