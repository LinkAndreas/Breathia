extension BreathCue.Focus {
    /// The SF Symbol shown beside a cue's text.
    var systemImage: String {
        switch self {
        case .nose: "nose"
        case .mouth: "mouth"
        case .sound: "waveform"
        case .lungs: "lungs"
        case .heart: "heart"
        case .ease: "leaf"
        }
    }
}
