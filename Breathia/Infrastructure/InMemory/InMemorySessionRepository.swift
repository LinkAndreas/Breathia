import Foundation

/// `SessionRepository` held in memory — for previews, tests, and as a fallback
/// when the on-device store can't be opened.
final class InMemorySessionRepository: SessionRepository {
    private var sessions: [SessionRecord]

    init(sessions: [SessionRecord] = []) {
        self.sessions = sessions.sorted { $0.date > $1.date }
    }

    func fetchAll() -> [SessionRecord] {
        sessions
    }

    func insert(_ session: SessionRecord) {
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        sessions.append(session)
        sessions.sort { $0.date > $1.date }
    }

    func delete(sessionID: SessionRecord.ID) {
        sessions.removeAll { $0.id == sessionID }
    }

    func deleteAll() {
        sessions.removeAll()
    }
}
