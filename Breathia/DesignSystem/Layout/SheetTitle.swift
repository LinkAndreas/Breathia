import SwiftUI

/// A sheet's title: the inline navigation title on iPhone and iPad, a centred
/// title bar on the Mac. Applied with `sheetTitle(_:)`.
struct SheetTitle: ViewModifier {
    let title: Text

    func body(content: Content) -> some View {
        #if os(macOS)
        content.safeAreaInset(edge: .top, spacing: 0) {
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
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
