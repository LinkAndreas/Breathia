import SwiftUI

/// Names the unit of the number above it in the breathing circle: which cycle of
/// the session this is, or how far through the set of breaths.
struct BreathingCircleCaption: View {
    let position: BreathingClock.Position
    /// Breaths in the whole session — the "of 60" under a breath number.
    let totalBreaths: Int

    var body: some View {
        switch position.readout {
        case .secondsLeft: Text("session.cycle \(position.cycle)")
        case .breathNumber: Text("session.breathOf \(totalBreaths)")
        }
    }
}
