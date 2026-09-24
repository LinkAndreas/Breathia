import SwiftUI

/// The countdown before a session on Apple Watch.
struct WatchCountdownView: View {
    let value: Int
    let technique: Technique

    var body: some View {
        VStack(spacing: 4) {
            Text("common.getReady")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: value)
            Text(technique.name)
                .font(.footnote)
                .foregroundStyle(technique.tint)
                .lineLimit(1)
        }
    }
}

#if DEBUG
#Preview {
    WatchCountdownView(value: 3, technique: TechniqueCatalog.all[1])
}
#endif
