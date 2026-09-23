import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Root of the full-screen session cover: countdown → session → results. The
/// session comes from `makeSession`, so this screen doesn't know which sensor,
/// cue player, or recorder it runs with.
struct SessionFlowView: View {
    /// Builds the session when the screen first appears.
    let makeSession: () -> BreathingSessionModel
    /// Leaves without a result (cancelled during the countdown).
    let onCancel: () -> Void
    /// Leaves the results screen, passing the session if it was recorded (long
    /// enough to be kept in History).
    let onFinish: (SessionRecord?) -> Void

    @State private var model: BreathingSessionModel?
    #if os(macOS)
    /// Holds off display sleep while the session is open.
    @State private var displayAwake: NSObjectProtocol?
    #endif

    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()

            if let model {
                stageView(for: model)
                    .animation(.smooth, value: model.stage)
            }
        }
        .onAppear(perform: startIfNeeded)
        // Away from the screen, cues and sensor readings stop: pause rather than let
        // the session and its Live Activity run on without the user.
        .sessionInterruptions(
            onInterrupt: { model?.interrupt() },
            onReturn: { model?.continueAfterInterruption() }
        )
        .onDisappear {
            model?.cancel()
            keepDisplayAwake(false)
        }
    }

    @ViewBuilder
    private func stageView(for model: BreathingSessionModel) -> some View {
        switch model.stage {
        case let .countdown(value):
            SessionCountdownView(value: value, startedAt: model.countdownStartedAt, technique: model.technique) {
                model.cancel()
                onCancel()
            }
            .transition(.opacity)
        case .running:
            BreathingSessionView(model: model)
                .transition(.opacity)
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        case let .completed(record):
            SessionResultsView(session: record) {
                onFinish(model.wasRecorded ? record : nil)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }

    private func startIfNeeded() {
        guard model == nil else { return }
        let model = makeSession()
        self.model = model
        model.start()
        keepDisplayAwake(true)
    }

    /// Keeps the screen on while breathing.
    private func keepDisplayAwake(_ isOn: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = isOn
        #elseif os(macOS)
        if isOn, displayAwake == nil {
            displayAwake = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "Breathing session"
            )
        } else if !isOn, let displayAwake {
            ProcessInfo.processInfo.endActivity(displayAwake)
            self.displayAwake = nil
        }
        #endif
    }
}

/// The countdown before a session: what's about to start, the seconds in a ring
/// that drains as they pass, and which phase comes first.
private struct SessionCountdownView: View {
    let value: Int
    /// When the countdown began; the ring drains continuously from there, and stays
    /// full while it's `nil` (waiting to start again after the user left the app).
    let startedAt: Date?
    let technique: Technique
    let onCancel: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        SessionArrangement {
            // The ring where the session's circle appears, the words beside or below it.
            ring
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } secondary: {
            VStack(spacing: 28) {
                heading
                firstPhase
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

    private var heading: some View {
        VStack(spacing: 6) {
            Text("common.getReady")
                .font(.title2.weight(.bold))
            Text(technique.name)
                .font(.headline)
                .foregroundStyle(technique.tint)
        }
        .multilineTextAlignment(.center)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .fill(technique.tint.opacity(0.10))
            // Thin like the live session's circle.
            Circle()
                .stroke(technique.tint.opacity(0.25), lineWidth: 2)
            // Drawn from the clock rather than animated: an animation starting as
            // the screen appears would also animate its first layout, which slides
            // a Mac sheet's content in from the top-left corner.
            TimelineView(.animation(paused: reduceMotion)) { context in
                Circle()
                    .trim(from: 0, to: ringProgress(at: context.date))
                    .stroke(technique.tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(value, format: .number)
                .font(.system(size: 104, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: value)
        }
        .frame(width: 220, height: 220)
        .background {
            // Centred on the ring and wider than it, so the tint wash reaches past
            // its pane.
            RadialGradient(
                colors: [technique.tint.opacity(0.16), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 380
            )
            .frame(width: 760, height: 760)
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(value, format: .number))
    }

    @ViewBuilder
    private var firstPhase: some View {
        if let firstPhase = technique.phases.first {
            Label {
                Text("session.countdown.firstPhase \(firstPhase.label)")
            } icon: {
                Image(systemName: "wind")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.Palette.elevated, in: .capsule)
        }
    }

    /// How much of the ring is left, running out as the session begins. Measured from
    /// one start time, so it drains evenly without a jump as each second ticks over.
    /// With Reduce Motion it steps down once per second instead.
    private func ringProgress(at date: Date) -> Double {
        let length = Double(BreathingSessionModel.countdownStart)
        guard let startedAt else { return 1 }
        guard !reduceMotion else { return Double(value - 1) / length }
        return max(0, 1 - date.timeIntervalSince(startedAt) / length)
    }
}

#if DEBUG
#Preview {
    let factory = PreviewStores.sessionFactory()
    SessionFlowView(
        makeSession: { factory.makeSession(for: TechniqueCatalog.all[1]) },
        onCancel: {},
        onFinish: { _ in }
    )
}
#endif
