import SwiftUI

/// A report card's small title, with an optional note of what's measured.
struct ReportCardTitle: View {
    let title: Text

    var body: some View {
        title
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}
