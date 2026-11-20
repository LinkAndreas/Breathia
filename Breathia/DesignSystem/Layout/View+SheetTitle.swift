import SwiftUI

extension View {
    /// The navigation title of a sheet: inline on iPhone and iPad. On the Mac it's drawn
    /// as a centred title bar, since a sheet's toolbar title sits at the leading edge
    /// and its centre slot isn't shown.
    func sheetTitle(_ title: LocalizedStringKey) -> some View {
        modifier(SheetTitle(title: Text(title)))
    }

    func sheetTitle(verbatim title: String) -> some View {
        modifier(SheetTitle(title: Text(verbatim: title)))
    }
}
