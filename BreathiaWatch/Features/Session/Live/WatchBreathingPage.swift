import SwiftUI

/// The breathing page: the face animated while the display is on, and redrawn once
/// a second once the wrist is down. Both draw the same face in the same place, so
/// raising or lowering the wrist only brightens or dims it.
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
                    // Always On: the running workout lets the watch redraw once a
                    // second — enough for every count, though not for the bar's motion.
                    TimelineView(WholeSecondSchedule(anchor: model.wholeSecondAnchor)) { context in
                        WatchBreathingFace(model: model, date: context.date, size: size, statusRoom: statusRoom, isDimmed: true)
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
