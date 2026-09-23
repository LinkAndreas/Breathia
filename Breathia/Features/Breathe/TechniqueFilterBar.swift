import SwiftUI

enum TechniqueFilter: Hashable, Identifiable {
    case all
    case category(TechniqueCategory)

    static var allCases: [TechniqueFilter] {
        [.all] + TechniqueCategory.allCases.map(TechniqueFilter.category)
    }

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "breathe.filter.all", comment: "Technique filter")
        case let .category(category): category.title
        }
    }

    func includes(_ technique: Technique) -> Bool {
        switch self {
        case .all: true
        case let .category(category): technique.category == category
        }
    }
}

extension Technique {
    /// Whether the technique's name, purpose, summary, category, or uses mention `query`.
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return ([name, summary, purpose, category.title] + bestFor)
            .contains { $0.localizedStandardContains(query) }
    }
}

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
                        chip(for: filter) {
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

    private func chip(for filter: TechniqueFilter, action: @escaping () -> Void) -> some View {
        let isSelected = filter == selection
        return Button(action: action) {
            Text(filter.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    } else {
                        Capsule()
                            .fill(Theme.Palette.elevated)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
