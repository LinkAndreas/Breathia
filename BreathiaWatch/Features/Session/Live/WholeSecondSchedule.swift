import SwiftUI

/// Redraws once a second, on the second of the session's own clock rather than the
/// wall clock's, so each count is drawn as it turns over. Always On allows no more
/// than this while a workout runs.
struct WholeSecondSchedule: TimelineSchedule {
    /// A moment the session's active time was a whole number of seconds.
    let anchor: Date

    /// How far past each turn to redraw, so the count read then is already the new one.
    private static let lead: TimeInterval = 0.05

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> some Sequence<Date> {
        let first = anchor.addingTimeInterval(
            (startDate.timeIntervalSince(anchor) - Self.lead).rounded(.down) + Self.lead
        )
        return sequence(first: first) { $0.addingTimeInterval(1) }
    }
}
