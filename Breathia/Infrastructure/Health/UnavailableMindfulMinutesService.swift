import Foundation

/// `MindfulMinutesService` for the Mac, which has no Apple Health: the Mac app has
/// no HealthKit entitlement, so it must never show the Health step or ask for access.
struct UnavailableMindfulMinutesService: MindfulMinutesService {
    var access: HealthAccess { .unavailable }

    func requestAccess() async -> HealthAccess { .unavailable }

    func save(_ session: SessionRecord) async throws {}
}
