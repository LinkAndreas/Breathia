import Foundation

/// What a technique is mainly used for. Drives grouping and filtering; the order
/// of the cases is the order categories appear in.
enum TechniqueCategory: String, CaseIterable, Identifiable, Hashable {
    case hrv, calm, stress, sleep, focus, energy, foundations

    var id: Self { self }

    var title: String {
        switch self {
        case .hrv: String(localized: "technique.category.hrvCoherence", comment: "Technique category")
        case .calm: String(localized: "technique.category.calm", comment: "Technique category")
        case .stress: String(localized: "technique.category.stressRelief", comment: "Technique category")
        case .sleep: String(localized: "technique.category.sleep", comment: "Technique category")
        case .focus: String(localized: "technique.category.focusPerformance", comment: "Technique category")
        case .energy: String(localized: "technique.category.energy", comment: "Technique category")
        case .foundations: String(localized: "technique.category.foundations", comment: "Technique category")
        }
    }

    var systemImage: String {
        switch self {
        case .hrv: "waveform.path.ecg"
        case .calm: "leaf"
        case .stress: "heart"
        case .sleep: "moon.stars"
        case .focus: "scope"
        case .energy: "bolt"
        case .foundations: "lungs"
        }
    }
}

/// Techniques of one category, for sectioned lists.
struct TechniqueGroup: Identifiable {
    let category: TechniqueCategory
    let techniques: [Technique]

    var id: TechniqueCategory { category }

    /// Groups `techniques` by category in category order, skipping empty categories.
    static func grouping(_ techniques: [Technique]) -> [TechniqueGroup] {
        TechniqueCategory.allCases.compactMap { category in
            let members = techniques.filter { $0.category == category }
            return members.isEmpty ? nil : TechniqueGroup(category: category, techniques: members)
        }
    }
}
