import SwiftUI

extension BreathingActivityAttributes {
    var tint: Color {
        Color(.sRGBLinear, red: tintRed, green: tintGreen, blue: tintBlue)
    }

    /// The whole session's time range, given when it ends.
    func sessionRange(endingAt end: Date) -> ClosedRange<Date> {
        min(end.addingTimeInterval(-sessionDuration), end)...end
    }
}
