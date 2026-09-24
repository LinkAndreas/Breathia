import SwiftUI

/// How to practise the technique, as numbered steps.
struct TechniqueSteps: View {
    let technique: Technique

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(technique.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(index + 1, format: .number)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(technique.tint, in: .circle)
                    Text(step)
                        .padding(.top, 1)
                }
            }
        }
    }
}
