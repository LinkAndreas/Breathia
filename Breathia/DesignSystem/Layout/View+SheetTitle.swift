import SwiftUI

extension View {
    /// The navigation title of a sheet: inline on iPhone and iPad. On the Mac it's drawn
    /// as a centred title bar, since a sheet's toolbar title sits at the leading edge
    /// and its centre slot isn't shown.
    func sheetTitle(_ title: LocalizedStringKey) -> some View {
        sheetTitle(Text(title))
    }

    func sheetTitle(verbatim title: String) -> some View {
        sheetTitle(Text(verbatim: title))
    }

    @ViewBuilder
    private func sheetTitle(_ title: Text) -> some View {
        #if os(macOS)
        safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                title
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                Divider()
            }
            .background(.bar)
        }
        #else
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
