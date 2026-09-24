import SwiftUI

/// "Get ready" over the name of the technique about to start.
struct CountdownHeading: View {
    let technique: Technique

    var body: some View {
        VStack(spacing: 6) {
            Text("common.getReady")
                .font(.title2.weight(.bold))
            Text(technique.name)
                .font(.headline)
                .foregroundStyle(technique.tint)
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
#Preview {
    CountdownHeading(technique: TechniqueCatalog.all[1])
        .padding()
}
#endif
