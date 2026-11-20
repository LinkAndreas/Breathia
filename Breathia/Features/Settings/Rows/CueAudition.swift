import SwiftUI

/// Plays a breath in and a breath out with a cue sound at a volume, so it can be
/// heard while choosing.
struct CueAuditioner: Equatable {
    private let play: (CueSound, Double) -> Void

    init(_ play: @escaping (CueSound, Double) -> Void) {
        self.play = play
    }

    func callAsFunction(_ sound: CueSound, volume: Double) {
        play(sound, volume)
    }

    /// The app sets one auditioner for its whole lifetime, so any two are the same
    /// as far as SwiftUI is concerned — views never need updating when it's set.
    static func == (lhs: Self, rhs: Self) -> Bool { true }

    /// Plays nothing — the default, so previews stay quiet.
    static let silent = CueAuditioner { _, _ in }
}

extension EnvironmentValues {
    @Entry var auditionCue = CueAuditioner.silent
}
