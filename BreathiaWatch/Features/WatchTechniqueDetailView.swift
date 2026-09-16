import SwiftUI

struct WatchTechniqueDetailView: View {
    let technique: Technique
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TechniqueOrb(technique: technique, size: 36)
                    .padding(.top, 4)

                Text(technique.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(technique.purpose)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(technique.patternLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(technique.tint)
                    .multilineTextAlignment(.center)

                Label(technique.durationLabel, systemImage: "timer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(action: onStart) {
                    Label("common.start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(technique.tint)
                .padding(.top, 6)

                Text(technique.safetyNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
        }
        .navigationTitle(technique.name)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchTechniqueDetailView(technique: TechniqueCatalog.all[1], onStart: {})
    }
}
#endif
