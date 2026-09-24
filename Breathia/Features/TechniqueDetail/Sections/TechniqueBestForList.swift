import SwiftUI

/// What the technique is best for, as a list with dots in its colour.
struct TechniqueBestForList: View {
    let technique: Technique

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(technique.bestFor, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(technique.tint)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(item)
                }
            }
        }
    }
}
