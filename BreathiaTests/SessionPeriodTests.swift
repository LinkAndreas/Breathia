import Foundation
import Testing
@testable import Breathia

struct SessionPeriodTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Wednesday, 23 September 2026, 14:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_790_172_000)

    private func daysAgo(_ days: Double, hour: Double = 9) -> Date {
        calendar.startOfDay(for: now).addingTimeInterval(-days * 86_400 + hour * 3_600)
    }

    private func period(_ date: Date) -> SessionPeriod {
        SessionPeriod(of: date, relativeTo: now, calendar: calendar)
    }

    @Test func placesRecentDaysInTheirPeriods() {
        #expect(period(daysAgo(0)) == .today)
        #expect(period(daysAgo(1)) == .yesterday)
        #expect(period(daysAgo(2)) == .previous7Days)
        #expect(period(daysAgo(6)) == .previous7Days)
        #expect(period(daysAgo(7)) == .previous30Days)
        #expect(period(daysAgo(29)) == .previous30Days)
    }

    @Test func groupsOlderSessionsByMonth() throws {
        let august = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))
        let lastYear = try #require(calendar.date(from: DateComponents(year: 2025, month: 12, day: 1)))
        #expect(period(daysAgo(30)) == .month(start: august))
        #expect(period(daysAgo(290)) == .month(start: lastYear))
    }

    @Test func titlesMonthsWithTheYearOnlyWhenItIsNotThisYear() throws {
        let august = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))
        let lastYear = try #require(calendar.date(from: DateComponents(year: 2025, month: 12, day: 1)))
        let thisYearTitle = SessionPeriod.month(start: august).title(relativeTo: now, calendar: calendar)
        let lastYearTitle = SessionPeriod.month(start: lastYear).title(relativeTo: now, calendar: calendar)
        #expect(!thisYearTitle.contains("2026"))
        #expect(lastYearTitle.contains("2025"))
    }

    @Test func groupsSessionsNewestFirstInOrder() {
        let technique = Technique.testTechnique(phases: [.inhale(4), .exhale(4)])
        let sessions = [0, 0, 1, 3, 12, 45].map { days in
            SessionRecordFactory.makeRecord(
                technique: technique, startedAt: daysAgo(Double(days)), duration: 60,
                heartRates: [], hrvValues: [], metric: .rmssd, source: .iPhone
            )
        }
        let groups = SessionGroup.grouping(sessions, relativeTo: now, calendar: calendar)
        #expect(groups.map(\.sessions.count) == [2, 1, 1, 1, 1])
        #expect(groups.prefix(4).map(\.period) == [.today, .yesterday, .previous7Days, .previous30Days])
    }
}
