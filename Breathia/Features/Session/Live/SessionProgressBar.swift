import SwiftUI

/// A thick bar in the technique's colour, with the elapsed time under its start
/// and the total under its end.
struct SessionProgressBar: View {
    let model: BreathingSessionModel

    private var tint: Color { model.technique.tint }

    var body: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(tint.opacity(0.18))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(tint)
                            .frame(width: proxy.size.width * model.progress)
                    }
                }
                .animation(.linear(duration: 0.2), value: model.progress)
            HStack {
                Text(verbatim: Formatters.clock(model.elapsed))
                Spacer()
                Text(verbatim: Formatters.clock(model.targetDuration))
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(Formatters.clock(model.elapsed)) / \(Formatters.clock(model.targetDuration))"))
    }
}

#if DEBUG
#Preview {
    SessionProgressBar(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
        .padding()
}
#endif
