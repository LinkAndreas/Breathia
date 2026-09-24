import SwiftUI

extension HRVTrend {
    var title: String {
        switch self {
        case .increasing: String(localized: "report.increasing", comment: "HRV trend")
        case .stable: String(localized: "report.stable", comment: "HRV trend")
        case .decreasing: String(localized: "report.decreasing", comment: "HRV trend")
        }
    }

    var shortLabel: String {
        switch self {
        case .increasing: String(localized: "report.hrvTrendUp")
        case .stable: String(localized: "report.hrvTrendSteady")
        case .decreasing: String(localized: "report.hrvTrendDown")
        }
    }

    var color: Color {
        switch self {
        case .increasing: .green
        case .stable: .secondary
        case .decreasing: Theme.Palette.tertiaryLabel
        }
    }
}
