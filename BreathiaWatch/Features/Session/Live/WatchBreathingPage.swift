import SwiftUI

/// The breathing page: the face animated while the display is on, and redrawn as
/// often as Always On allows once the wrist is down.
struct WatchBreathingPage: View {
    let model: BreathingSessionModel

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        GeometryReader { proxy in
            // The page reaches up beside the clock: the status takes the clock's row,
            // and everything else moves up with it.
            let statusRoom = proxy.safeAreaInsets.top * 0.56
            let size = CGSize(width: proxy.size.width, height: proxy.size.height + proxy.safeAreaInsets.top)
            Group {
                if isLuminanceReduced {
                    // Always On: the watch redraws once a second while a workout runs,
                    // enough for the count but not for the circle's motion. Without
                    // one it redraws about once a minute, too seldom for a count.
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        if context.cadence <= .seconds {
                            WatchBreathingFace(model: model, date: context.date, size: size, statusRoom: statusRoom, isDimmed: true)
                        } else {
                            WatchGlanceFace(model: model)
                        }
                    }
                } else {
                    TimelineView(.animation(paused: model.isPaused)) { context in
                        WatchBreathingFace(model: model, date: context.date, size: size, statusRoom: statusRoom)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .offset(y: -proxy.safeAreaInsets.top)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchBreathingPage(model: WatchPreviewData.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
    }
}
#endif
