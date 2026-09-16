import Foundation

/// The built-in breathing techniques, grouped into categories. Each category has
/// its own hue range, so techniques that serve the same purpose share a colour
/// family while staying distinguishable.
///
/// Technique copy is localized through the app's string catalog, under keys of
/// the form `technique.<id>.<field>` (list items add a 1-based index).
enum TechniqueCatalog {
    static let all: [Technique] = hrv + calm + stress + sleep + focus + energy + foundations

    static let defaultTechniqueID: Technique.ID = "box"

    /// Looks a technique up by id, falling back to the default so stale ids
    /// (e.g. from an older settings file) never crash the UI.
    static func technique(withID id: Technique.ID) -> Technique {
        all.first { $0.id == id } ?? all.first { $0.id == defaultTechniqueID } ?? all[0]
    }

    // MARK: HRV & Coherence

    private static let hrv: [Technique] = [
        Technique(
            id: "resonance", name: t("technique.resonance.name"),
            summary: t("technique.resonance.summary"), purpose: t("technique.resonance.purpose"),
            category: .hrv, isBeginnerFriendly: true, recommendedDuration: 600,
            phases: [.inhale(5), .exhale(5)],
            howItWorks: t("technique.resonance.howItWorks"),
            bestFor: [t("technique.resonance.bestFor.1"), t("technique.resonance.bestFor.2"), t("technique.resonance.bestFor.3")],
            steps: [t("technique.resonance.steps.1"), t("technique.resonance.steps.2"), t("technique.resonance.steps.3"), t("technique.resonance.steps.4")],
            safetyNote: t("technique.resonance.safetyNote"),
            hue: 340
        ),
        Technique(
            id: "coherent", name: t("technique.coherent.name"),
            summary: t("technique.coherent.summary"), purpose: t("technique.coherent.purpose"),
            category: .hrv, isBeginnerFriendly: true, recommendedDuration: 600,
            phases: [.inhale(6), .exhale(6)],
            howItWorks: t("technique.coherent.howItWorks"),
            bestFor: [t("technique.coherent.bestFor.1"), t("technique.coherent.bestFor.2"), t("technique.coherent.bestFor.3")],
            steps: [t("technique.coherent.steps.1"), t("technique.coherent.steps.2"), t("technique.coherent.steps.3"), t("technique.coherent.steps.4")],
            safetyNote: t("technique.coherent.safetyNote"),
            hue: 328
        ),
        Technique(
            id: "heartFocused", name: t("technique.heartFocused.name"),
            summary: t("technique.heartFocused.summary"), purpose: t("technique.heartFocused.purpose"),
            category: .hrv, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(5), .exhale(5)],
            howItWorks: t("technique.heartFocused.howItWorks"),
            bestFor: [t("technique.heartFocused.bestFor.1"), t("technique.heartFocused.bestFor.2"), t("technique.heartFocused.bestFor.3")],
            steps: [t("technique.heartFocused.steps.1"), t("technique.heartFocused.steps.2"), t("technique.heartFocused.steps.3"), t("technique.heartFocused.steps.4")],
            safetyNote: t("technique.heartFocused.safetyNote"),
            hue: 352
        ),
    ]

    // MARK: Calm

    private static let calm: [Technique] = [
        Technique(
            id: "relax", name: t("technique.relax.name"),
            summary: t("technique.relax.summary"), purpose: t("technique.relax.purpose"),
            category: .calm, isBeginnerFriendly: true, recommendedDuration: 360,
            phases: [.inhale(4), .exhale(6)],
            howItWorks: t("technique.relax.howItWorks"),
            bestFor: [t("technique.relax.bestFor.1"), t("technique.relax.bestFor.2"), t("technique.relax.bestFor.3")],
            steps: [t("technique.relax.steps.1"), t("technique.relax.steps.2"), t("technique.relax.steps.3")],
            safetyNote: t("technique.relax.safetyNote"),
            hue: 190
        ),
        Technique(
            id: "ujjayi", name: t("technique.ujjayi.name"),
            summary: t("technique.ujjayi.summary"), purpose: t("technique.ujjayi.purpose"),
            category: .calm, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(5), .exhale(5)],
            howItWorks: t("technique.ujjayi.howItWorks"),
            bestFor: [t("technique.ujjayi.bestFor.1"), t("technique.ujjayi.bestFor.2"), t("technique.ujjayi.bestFor.3")],
            steps: [t("technique.ujjayi.steps.1"), t("technique.ujjayi.steps.2"), t("technique.ujjayi.steps.3"), t("technique.ujjayi.steps.4")],
            safetyNote: t("technique.ujjayi.safetyNote"),
            hue: 202
        ),
        Technique(
            id: "humming", name: t("technique.humming.name"),
            summary: t("technique.humming.summary"), purpose: t("technique.humming.purpose"),
            category: .calm, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(4), .exhale(6)],
            howItWorks: t("technique.humming.howItWorks"),
            bestFor: [t("technique.humming.bestFor.1"), t("technique.humming.bestFor.2"), t("technique.humming.bestFor.3")],
            steps: [t("technique.humming.steps.1"), t("technique.humming.steps.2"), t("technique.humming.steps.3"), t("technique.humming.steps.4")],
            safetyNote: t("technique.humming.safetyNote"),
            hue: 178
        ),
        Technique(
            id: "sitali", name: t("technique.sitali.name"),
            summary: t("technique.sitali.summary"), purpose: t("technique.sitali.purpose"),
            category: .calm, isBeginnerFriendly: true, recommendedDuration: 240,
            phases: [.inhale(4), .exhale(6)],
            howItWorks: t("technique.sitali.howItWorks"),
            bestFor: [t("technique.sitali.bestFor.1"), t("technique.sitali.bestFor.2"), t("technique.sitali.bestFor.3")],
            steps: [t("technique.sitali.steps.1"), t("technique.sitali.steps.2"), t("technique.sitali.steps.3"), t("technique.sitali.steps.4")],
            safetyNote: t("technique.sitali.safetyNote"),
            hue: 214
        ),
    ]

    // MARK: Stress Relief

    private static let stress: [Technique] = [
        Technique(
            id: "sigh", name: t("technique.sigh.name"),
            summary: t("technique.sigh.summary"), purpose: t("technique.sigh.purpose"),
            category: .stress, isBeginnerFriendly: true, recommendedDuration: 180,
            phases: [.inhale(2, scale: 1.0), .inhale(1), .exhale(6)],
            howItWorks: t("technique.sigh.howItWorks"),
            bestFor: [t("technique.sigh.bestFor.1"), t("technique.sigh.bestFor.2"), t("technique.sigh.bestFor.3")],
            steps: [t("technique.sigh.steps.1"), t("technique.sigh.steps.2"), t("technique.sigh.steps.3"), t("technique.sigh.steps.4")],
            safetyNote: t("technique.sigh.safetyNote"),
            hue: 150
        ),
        Technique(
            id: "sevenEleven", name: t("technique.sevenEleven.name"),
            summary: t("technique.sevenEleven.summary"), purpose: t("technique.sevenEleven.purpose"),
            category: .stress, isBeginnerFriendly: false, recommendedDuration: 300,
            phases: [.inhale(7), .exhale(11)],
            howItWorks: t("technique.sevenEleven.howItWorks"),
            bestFor: [t("technique.sevenEleven.bestFor.1"), t("technique.sevenEleven.bestFor.2"), t("technique.sevenEleven.bestFor.3")],
            steps: [t("technique.sevenEleven.steps.1"), t("technique.sevenEleven.steps.2"), t("technique.sevenEleven.steps.3"), t("technique.sevenEleven.steps.4")],
            safetyNote: t("technique.sevenEleven.safetyNote"),
            hue: 138
        ),
        Technique(
            id: "lion", name: t("technique.lion.name"),
            summary: t("technique.lion.summary"), purpose: t("technique.lion.purpose"),
            category: .stress, isBeginnerFriendly: true, recommendedDuration: 120,
            phases: [.inhale(4), .exhale(3)],
            howItWorks: t("technique.lion.howItWorks"),
            bestFor: [t("technique.lion.bestFor.1"), t("technique.lion.bestFor.2"), t("technique.lion.bestFor.3")],
            steps: [t("technique.lion.steps.1"), t("technique.lion.steps.2"), t("technique.lion.steps.3"), t("technique.lion.steps.4")],
            safetyNote: t("technique.lion.safetyNote"),
            hue: 162
        ),
    ]

    // MARK: Sleep

    private static let sleep: [Technique] = [
        Technique(
            id: "478", name: t("technique.478.name"),
            summary: t("technique.478.summary"), purpose: t("technique.478.purpose"),
            category: .sleep, isBeginnerFriendly: false, recommendedDuration: 240,
            phases: [.inhale(4), .hold(7, scale: 1.15), .exhale(8)],
            howItWorks: t("technique.478.howItWorks"),
            bestFor: [t("technique.478.bestFor.1"), t("technique.478.bestFor.2"), t("technique.478.bestFor.3")],
            steps: [t("technique.478.steps.1"), t("technique.478.steps.2"), t("technique.478.steps.3"), t("technique.478.steps.4")],
            safetyNote: t("technique.478.safetyNote"),
            hue: 285
        ),
        Technique(
            id: "twoToOne", name: t("technique.twoToOne.name"),
            summary: t("technique.twoToOne.summary"), purpose: t("technique.twoToOne.purpose"),
            category: .sleep, isBeginnerFriendly: true, recommendedDuration: 360,
            phases: [.inhale(4), .exhale(8)],
            howItWorks: t("technique.twoToOne.howItWorks"),
            bestFor: [t("technique.twoToOne.bestFor.1"), t("technique.twoToOne.bestFor.2"), t("technique.twoToOne.bestFor.3")],
            steps: [t("technique.twoToOne.steps.1"), t("technique.twoToOne.steps.2"), t("technique.twoToOne.steps.3"), t("technique.twoToOne.steps.4")],
            safetyNote: t("technique.twoToOne.safetyNote"),
            hue: 297
        ),
        Technique(
            id: "moonBreath", name: t("technique.moonBreath.name"),
            summary: t("technique.moonBreath.summary"), purpose: t("technique.moonBreath.purpose"),
            category: .sleep, isBeginnerFriendly: false, recommendedDuration: 300,
            phases: [.inhale(4), .exhale(6)],
            howItWorks: t("technique.moonBreath.howItWorks"),
            bestFor: [t("technique.moonBreath.bestFor.1"), t("technique.moonBreath.bestFor.2"), t("technique.moonBreath.bestFor.3")],
            steps: [t("technique.moonBreath.steps.1"), t("technique.moonBreath.steps.2"), t("technique.moonBreath.steps.3"), t("technique.moonBreath.steps.4")],
            safetyNote: t("technique.moonBreath.safetyNote"),
            hue: 273
        ),
    ]

    // MARK: Focus & Performance

    private static let focus: [Technique] = [
        Technique(
            id: "box", name: t("technique.box.name"),
            summary: t("technique.box.summary"), purpose: t("technique.box.purpose"),
            category: .focus, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(4), .hold(4, scale: 1.15), .exhale(4), .hold(4, scale: 0.8)],
            howItWorks: t("technique.box.howItWorks"),
            bestFor: [t("technique.box.bestFor.1"), t("technique.box.bestFor.2"), t("technique.box.bestFor.3")],
            steps: [t("technique.box.steps.1"), t("technique.box.steps.2"), t("technique.box.steps.3"), t("technique.box.steps.4"), t("technique.box.steps.5")],
            safetyNote: t("technique.box.safetyNote"),
            hue: 28
        ),
        Technique(
            id: "triangle", name: t("technique.triangle.name"),
            summary: t("technique.triangle.summary"), purpose: t("technique.triangle.purpose"),
            category: .focus, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(4), .hold(4, scale: 1.15), .exhale(4)],
            howItWorks: t("technique.triangle.howItWorks"),
            bestFor: [t("technique.triangle.bestFor.1"), t("technique.triangle.bestFor.2"), t("technique.triangle.bestFor.3")],
            steps: [t("technique.triangle.steps.1"), t("technique.triangle.steps.2"), t("technique.triangle.steps.3"), t("technique.triangle.steps.4")],
            safetyNote: t("technique.triangle.safetyNote"),
            hue: 40
        ),
        Technique(
            id: "altnostril", name: t("technique.altnostril.name"),
            summary: t("technique.altnostril.summary"), purpose: t("technique.altnostril.purpose"),
            category: .focus, isBeginnerFriendly: false, recommendedDuration: 300,
            phases: [.inhale(4), .hold(2, scale: 1.15), .exhale(4), .hold(2, scale: 0.8)],
            howItWorks: t("technique.altnostril.howItWorks"),
            bestFor: [t("technique.altnostril.bestFor.1"), t("technique.altnostril.bestFor.2"), t("technique.altnostril.bestFor.3")],
            steps: [t("technique.altnostril.steps.1"), t("technique.altnostril.steps.2"), t("technique.altnostril.steps.3"), t("technique.altnostril.steps.4"), t("technique.altnostril.steps.5")],
            safetyNote: t("technique.altnostril.safetyNote"),
            hue: 16
        ),
        Technique(
            id: "buteyko", name: t("technique.buteyko.name"),
            summary: t("technique.buteyko.summary"), purpose: t("technique.buteyko.purpose"),
            category: .focus, isBeginnerFriendly: false, recommendedDuration: 300,
            phases: [.inhale(3, scale: 1.05), .exhale(3, scale: 0.85), .hold(4, scale: 0.85)],
            howItWorks: t("technique.buteyko.howItWorks"),
            bestFor: [t("technique.buteyko.bestFor.1"), t("technique.buteyko.bestFor.2"), t("technique.buteyko.bestFor.3")],
            steps: [t("technique.buteyko.steps.1"), t("technique.buteyko.steps.2"), t("technique.buteyko.steps.3"), t("technique.buteyko.steps.4")],
            safetyNote: t("technique.buteyko.safetyNote"),
            hue: 52
        ),
        Technique(
            id: "recovery", name: t("technique.recovery.name"),
            summary: t("technique.recovery.summary"), purpose: t("technique.recovery.purpose"),
            category: .focus, isBeginnerFriendly: true, recommendedDuration: 180,
            phases: [.inhale(3), .exhale(6)],
            howItWorks: t("technique.recovery.howItWorks"),
            bestFor: [t("technique.recovery.bestFor.1"), t("technique.recovery.bestFor.2"), t("technique.recovery.bestFor.3")],
            steps: [t("technique.recovery.steps.1"), t("technique.recovery.steps.2"), t("technique.recovery.steps.3"), t("technique.recovery.steps.4")],
            safetyNote: t("technique.recovery.safetyNote"),
            hue: 4
        ),
    ]

    // MARK: Energy

    private static let energy: [Technique] = [
        Technique(
            id: "sunBreath", name: t("technique.sunBreath.name"),
            summary: t("technique.sunBreath.summary"), purpose: t("technique.sunBreath.purpose"),
            category: .energy, isBeginnerFriendly: false, recommendedDuration: 240,
            phases: [.inhale(4), .exhale(4)],
            howItWorks: t("technique.sunBreath.howItWorks"),
            bestFor: [t("technique.sunBreath.bestFor.1"), t("technique.sunBreath.bestFor.2"), t("technique.sunBreath.bestFor.3")],
            steps: [t("technique.sunBreath.steps.1"), t("technique.sunBreath.steps.2"), t("technique.sunBreath.steps.3"), t("technique.sunBreath.steps.4")],
            safetyNote: t("technique.sunBreath.safetyNote"),
            hue: 75
        ),
        Technique(
            id: "bellows", name: t("technique.bellows.name"),
            summary: t("technique.bellows.summary"), purpose: t("technique.bellows.purpose"),
            category: .energy, isBeginnerFriendly: false, recommendedDuration: 120,
            phases: [.inhale(1, scale: 1.1), .exhale(1, scale: 0.85)],
            howItWorks: t("technique.bellows.howItWorks"),
            bestFor: [t("technique.bellows.bestFor.1"), t("technique.bellows.bestFor.2"), t("technique.bellows.bestFor.3")],
            steps: [t("technique.bellows.steps.1"), t("technique.bellows.steps.2"), t("technique.bellows.steps.3"), t("technique.bellows.steps.4")],
            safetyNote: t("technique.bellows.safetyNote"),
            hue: 88
        ),
    ]

    // MARK: Foundations

    private static let foundations: [Technique] = [
        Technique(
            id: "belly", name: t("technique.belly.name"),
            summary: t("technique.belly.summary"), purpose: t("technique.belly.purpose"),
            category: .foundations, isBeginnerFriendly: true, recommendedDuration: 360,
            phases: [.inhale(6), .exhale(6)],
            howItWorks: t("technique.belly.howItWorks"),
            bestFor: [t("technique.belly.bestFor.1"), t("technique.belly.bestFor.2"), t("technique.belly.bestFor.3")],
            steps: [t("technique.belly.steps.1"), t("technique.belly.steps.2"), t("technique.belly.steps.3"), t("technique.belly.steps.4")],
            safetyNote: t("technique.belly.safetyNote"),
            hue: 236
        ),
        Technique(
            id: "equal", name: t("technique.equal.name"),
            summary: t("technique.equal.summary"), purpose: t("technique.equal.purpose"),
            category: .foundations, isBeginnerFriendly: true, recommendedDuration: 480,
            phases: [.inhale(4), .exhale(4)],
            howItWorks: t("technique.equal.howItWorks"),
            bestFor: [t("technique.equal.bestFor.1"), t("technique.equal.bestFor.2"), t("technique.equal.bestFor.3")],
            steps: [t("technique.equal.steps.1"), t("technique.equal.steps.2"), t("technique.equal.steps.3"), t("technique.equal.steps.4")],
            safetyNote: t("technique.equal.safetyNote"),
            hue: 248
        ),
        Technique(
            id: "threePart", name: t("technique.threePart.name"),
            summary: t("technique.threePart.summary"), purpose: t("technique.threePart.purpose"),
            category: .foundations, isBeginnerFriendly: true, recommendedDuration: 300,
            phases: [.inhale(2, scale: 0.92), .inhale(2, scale: 1.03), .inhale(2), .exhale(6)],
            howItWorks: t("technique.threePart.howItWorks"),
            bestFor: [t("technique.threePart.bestFor.1"), t("technique.threePart.bestFor.2"), t("technique.threePart.bestFor.3")],
            steps: [t("technique.threePart.steps.1"), t("technique.threePart.steps.2"), t("technique.threePart.steps.3"), t("technique.threePart.steps.4"), t("technique.threePart.steps.5")],
            safetyNote: t("technique.threePart.safetyNote"),
            hue: 260
        ),
        Technique(
            id: "pursedLip", name: t("technique.pursedLip.name"),
            summary: t("technique.pursedLip.summary"), purpose: t("technique.pursedLip.purpose"),
            category: .foundations, isBeginnerFriendly: true, recommendedDuration: 180,
            phases: [.inhale(2), .exhale(4)],
            howItWorks: t("technique.pursedLip.howItWorks"),
            bestFor: [t("technique.pursedLip.bestFor.1"), t("technique.pursedLip.bestFor.2"), t("technique.pursedLip.bestFor.3")],
            steps: [t("technique.pursedLip.steps.1"), t("technique.pursedLip.steps.2"), t("technique.pursedLip.steps.3"), t("technique.pursedLip.steps.4")],
            safetyNote: t("technique.pursedLip.safetyNote"),
            hue: 224
        ),
    ]
}

private func t(_ key: String.LocalizationValue) -> String {
    String(localized: key)
}
