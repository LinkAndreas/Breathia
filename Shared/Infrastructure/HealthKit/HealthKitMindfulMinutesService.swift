import Foundation
import HealthKit
import OSLog

/// `MindfulMinutesService` backed by HealthKit. Only write access to Mindful
/// Minutes is requested — Breathia never reads Health data here. HealthKit
/// reports write permission accurately, so `access` can tell Settings when it was denied.
final class HealthKitMindfulMinutesService: MindfulMinutesService {
    static let mindfulSessionType = HKCategoryType(.mindfulSession)

    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "Breathia", category: "Health")

    var access: HealthAccess {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
        return switch healthStore.authorizationStatus(for: Self.mindfulSessionType) {
        case .sharingAuthorized: .allowed
        case .sharingDenied: .denied
        default: .notDetermined
        }
    }

    func requestAccess() async -> HealthAccess {
        guard access == .notDetermined else { return access }
        do {
            try await healthStore.requestAuthorization(toShare: [Self.mindfulSessionType], read: [])
        } catch {
            logger.error("Requesting Health access failed: \(String(describing: error), privacy: .public)")
        }
        return access
    }

    /// Saves `session` as a mindful session spanning its active duration. The
    /// session's id is stored as the sample's external id, linking it to History.
    func save(_ session: SessionRecord) async throws {
        let sample = HKCategorySample(
            type: Self.mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: session.date,
            end: session.date.addingTimeInterval(session.duration),
            metadata: [HKMetadataKeyExternalUUID: session.id.uuidString]
        )
        try await healthStore.save(sample)
    }
}
