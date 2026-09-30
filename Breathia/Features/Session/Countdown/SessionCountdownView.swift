import SwiftUI

/// The countdown before a session: what's about to start, the seconds in a ring
/// that drains as they pass, and which phase comes first.
struct SessionCountdownView: View {
    let value: Int
    /// When the countdown began; the ring drains continuously from there, and stays
    /// full while it's `nil` (waiting to start again after the user left the app).
    let startedAt: Date?
    let technique: Technique
    let onCancel: () -> Void

    var body: some View {
        SessionArrangement {
            // The ring where the session's circle appears, the words beside or below it.
            VStack(spacing: 0) {
                CountdownRing(value: value, startedAt: startedAt, tint: technique.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The first breath's cue, where the session shows it — so the ring
                // and the circle share a centre, and the cue is read before it's due.
                BreathCueSlot(technique: technique, cue: technique.phases.first?.cue(inCycle: 1))
            }
        } secondary: {
            VStack(spacing: 28) {
                CountdownHeading(technique: technique)
                CountdownFirstPhase(technique: technique)
                #if os(macOS)
                // A standard push button, as in Mac sheets; Escape cancels too.
                Button("common.cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(iOS)
        // The system's close button in the navigation bar, shown for the countdown only.
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close, action: onCancel)
            }
        }
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SessionCountdownView(value: 3, startedAt: .now, technique: TechniqueCatalog.all[1], onCancel: {})
    }
}
#endif
