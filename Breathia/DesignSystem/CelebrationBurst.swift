import SwiftUI

/// A burst of colourful hearts and sparkles rising from the bottom of its frame,
/// played each time `trigger` changes — the thank-you after a purchase. Ignores
/// touches. With Reduce Motion, a single heart fades in and out instead.
struct CelebrationBurst: View {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [Burst] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(bursts) { burst in
                    ForEach(burst.particles) { particle in
                        ParticleView(particle: particle, area: proxy.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            let burst = Burst(particles: reduceMotion ? [.calm] : (0..<30).map { _ in .random() })
            bursts.append(burst)
            Task {
                try? await Task.sleep(for: .seconds(3))
                bursts.removeAll { $0.id == burst.id }
            }
        }
    }
}

private struct Burst: Identifiable {
    let id = UUID()
    let particles: [Particle]
}

private struct Particle: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    /// Horizontal start, as a fraction of the width.
    let startX: CGFloat
    /// Sideways drift in points.
    let drift: CGFloat
    /// How high it rises, as a fraction of the height.
    let rise: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double

    static func random() -> Particle {
        Particle(
            symbol: Int.random(in: 0..<4) == 0 ? "sparkle" : "heart.fill",
            color: [.pink, .red, .orange, .yellow, .purple, .mint].randomElement()!,
            startX: .random(in: 0.15...0.85),
            drift: .random(in: -90...90),
            rise: .random(in: 0.45...0.9),
            size: .random(in: 14...32),
            rotation: .random(in: -45...45),
            delay: .random(in: 0...0.35),
            duration: .random(in: 1.4...2.2)
        )
    }

    static var calm: Particle {
        Particle(symbol: "heart.fill", color: .pink, startX: 0.5, drift: 0, rise: 0.45, size: 56, rotation: 0, delay: 0, duration: 1.4)
    }
}

private struct ParticleView: View {
    let particle: Particle
    let area: CGSize

    @State private var isFlying = false
    @State private var isFaded = false

    var body: some View {
        Image(systemName: particle.symbol)
            .font(.system(size: particle.size, weight: .bold))
            .foregroundStyle(particle.color.gradient)
            .scaleEffect(isFlying ? 1 : 0.2)
            .rotationEffect(.degrees(isFlying ? particle.rotation : 0))
            .opacity(isFaded ? 0 : 1)
            .position(
                x: area.width * particle.startX + (isFlying ? particle.drift : 0),
                y: area.height * (isFlying ? 1 - particle.rise : 0.95)
            )
            .onAppear {
                withAnimation(.easeOut(duration: particle.duration).delay(particle.delay)) {
                    isFlying = true
                }
                // Stay visible for most of the flight, then fade out at the top.
                withAnimation(.easeIn(duration: particle.duration * 0.4).delay(particle.delay + particle.duration * 0.6)) {
                    isFaded = true
                }
            }
    }
}

#if DEBUG
#Preview {
    struct Demo: View {
        @State private var count = 0
        var body: some View {
            Button { count += 1 } label: { Text(verbatim: "Celebrate") }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { CelebrationBurst(trigger: count) }
        }
    }
    return Demo()
}
#endif
