import Foundation

enum Formatters {
    /// "5:00", "12:34"
    static func clock(_ seconds: TimeInterval) -> String {
        Duration.seconds(Int(max(0, seconds))).formatted(.time(pattern: .minuteSecond))
    }

    /// "Today", "Yesterday", a weekday within the last week, otherwise "Sep 8".
    static func relativeDay(_ date: Date, relativeTo now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return String(localized: "format.today") }
        if calendar.isDateInYesterday(date) { return String(localized: "format.yesterday") }

        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? .max
        if (0..<7).contains(days) {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
