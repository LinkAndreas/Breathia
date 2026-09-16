import Foundation

/// Turns the HRV samples collected so far into a short piece of live feedback.
struct BiofeedbackAnalyzer {
    enum Feedback: Equatable {
        case collecting
        case settling
        case stable
        case increasing
        case synchronized

        var title: String {
            switch self {
            case .collecting: String(localized: "biofeedback.collectingHRVData")
            case .settling: String(localized: "biofeedback.settlingIn")
            case .stable: String(localized: "biofeedback.hrvStable")
            case .increasing: String(localized: "biofeedback.hrvIncreasing")
            case .synchronized: String(localized: "biofeedback.goodSynchronization")
            }
        }
    }

    let sensitivity: FeedbackSensitivity

    /// Compares recent HRV against the session's opening baseline. Lower
    /// sensitivity waits longer and needs a bigger change before responding.
    func feedback(elapsed: TimeInterval, samples: [Double]) -> Feedback {
        let multiplier = sensitivity.multiplier
        let window = 15

        guard elapsed >= 20 * multiplier, samples.count >= window else { return .collecting }
        guard elapsed >= 45 * multiplier, samples.count >= window * 2 else { return .settling }

        let baseline = samples.prefix(window).reduce(0, +) / Double(window)
        let recent = samples.suffix(window).reduce(0, +) / Double(window)
        guard baseline > 0 else { return .stable }

        let ratio = recent / baseline
        if ratio >= 1 + 0.2 * multiplier { return .synchronized }
        if ratio >= 1 + 0.08 * multiplier { return .increasing }
        return .stable
    }
}
