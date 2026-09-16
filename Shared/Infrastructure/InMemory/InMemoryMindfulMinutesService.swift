// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// `MindfulMinutesService` held in memory — for previews and tests.
final class InMemoryMindfulMinutesService: MindfulMinutesService {
    private(set) var access: HealthAccess
    private(set) var savedSessions: [SessionRecord] = []

    init(access: HealthAccess = .notDetermined) {
        self.access = access
    }

    func requestAccess() async -> HealthAccess {
        if access == .notDetermined {
            access = .allowed
        }
        return access
    }

    func save(_ session: SessionRecord) async throws {
        savedSessions.append(session)
    }
}
#endif
