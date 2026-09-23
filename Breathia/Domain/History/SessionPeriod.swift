import Foundation

/// When a session happened, as History groups it — the periods Notes and Mail use:
/// today, yesterday, the rest of the last week and month, then month by month.
enum SessionPeriod: Hashable {
    case today
    case yesterday
    case previous7Days
    case previous30Days
    /// A calendar month; `start` is its first day.
    case month(start: Date)

    init(of date: Date, relativeTo now: Date = .now, calendar: Calendar = .current) {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: now)
        ).day ?? .max
        switch days {
        case ...0: self = .today
        case 1: self = .yesterday
        case 2..<7: self = .previous7Days
        case 7..<30: self = .previous30Days
        default:
            let start = calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
            self = .month(start: start)
        }
    }

    /// "Today", "Previous 7 Days", "August" — with the year for a month of an
    /// earlier year.
    func title(relativeTo now: Date = .now, calendar: Calendar = .current) -> String {
        switch self {
        case .today:
            String(localized: "format.today")
        case .yesterday:
            String(localized: "format.yesterday")
        case .previous7Days:
            String(localized: "history.section.previous7Days")
        case .previous30Days:
            String(localized: "history.section.previous30Days")
        case let .month(start):
            calendar.isDate(start, equalTo: now, toGranularity: .year)
                ? start.formatted(.dateTime.month(.wide))
                : start.formatted(.dateTime.month(.wide).year())
        }
    }
}

/// A period's sessions, newest first.
struct SessionGroup: Identifiable {
    let period: SessionPeriod
    let sessions: [SessionRecord]

    var id: SessionPeriod { period }

    /// Groups `sessions`, given newest first, by period, keeping that order.
    static func grouping(
        _ sessions: [SessionRecord],
        relativeTo now: Date = .now,
        calendar: Calendar = .current
    ) -> [SessionGroup] {
        var groups: [SessionGroup] = []
        for session in sessions {
            let period = SessionPeriod(of: session.date, relativeTo: now, calendar: calendar)
            if groups.last?.period == period {
                groups[groups.count - 1] = SessionGroup(period: period, sessions: groups[groups.count - 1].sessions + [session])
            } else {
                groups.append(SessionGroup(period: period, sessions: [session]))
            }
        }
        return groups
    }
}
