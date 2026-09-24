import Foundation

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
