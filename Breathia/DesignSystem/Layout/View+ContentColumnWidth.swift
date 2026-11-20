import SwiftUI

extension View {
    /// Width of the content column (the section's list) on iPad and Mac.
    func contentColumnWidth() -> some View {
        navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 480)
            #if os(macOS)
            // macOS doesn't always pass a column's width preference on to the split
            // view; a minimum frame keeps the list from collapsing.
            .frame(minWidth: 320, idealWidth: 380)
            #endif
    }
}
