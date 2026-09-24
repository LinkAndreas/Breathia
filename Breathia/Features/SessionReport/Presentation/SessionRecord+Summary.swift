import Foundation

extension SessionRecord {
    var summaryText: String {
        guard hasSensorData else {
            return String(localized: "report.sessionsWithoutASensor")
        }
        return switch hrv?.trend {
        case .increasing: String(localized: "report.yourHRVRose")
        case .stable: String(localized: "report.yourHRVStayedFairly")
        case .decreasing: String(localized: "report.yourHRVDippedSlightly")
        case nil: String(localized: "report.theSessionWasToo")
        }
    }
}
