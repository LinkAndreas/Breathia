import SwiftUI

/// Horizontally scrolling category chips. One highlight capsule slides between
/// the chips, and the chosen chip is scrolled into view.
struct TechniqueFilterBar: View {
    @Binding var selection: TechniqueFilter

    @Namespace private var namespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TechniqueFilter.allCases) { filter in
                        TechniqueFilterChip(filter: filter, isSelected: filter == selection, namespace: namespace) {
                            withAnimation(.snappy(duration: 0.3)) {
                                selection = filter
                                proxy.scrollTo(filter, anchor: .center)
                            }
                        }
                        .id(filter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            // A scroll view draws into the safe area along its axis; stop at the edge
            // instead, so the chips don't run under a vertical status bar.
            .clipped()
        }
    }
}

#if DEBUG
#Preview {
    TechniqueFilterBar(selection: .constant(.all))
}
#endif
