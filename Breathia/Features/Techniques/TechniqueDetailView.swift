import SwiftUI

struct TechniqueDetailView: View {
    let technique: Technique
    let onStart: (Technique) -> Void

    #if os(macOS)
    /// Width available to the page, for choosing one or two text columns.
    @State private var contentWidth: CGFloat = 0
    #endif

    var body: some View {
        #if os(macOS)
        macBody
        #else
        phoneBody
        #endif
    }

    // MARK: iPhone and iPad

    #if !os(macOS)
    private var phoneBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                RhythmCard(technique: technique)
                    .padding(.top, 18)

                SectionHeader(title: "technique.detail.howItWorks")
                howItWorks
                    .padding(.horizontal, 4)

                SectionHeader(title: "technique.detail.bestFor")
                bestFor
                    .padding(.horizontal, 4)

                SectionHeader(title: "technique.detail.howToPractice")
                howToPractice
                    .padding(.horizontal, 4)

                Callout(text: technique.safetyNote, isSecondary: true)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .readableContentWidth()
        }
        .background(Theme.Palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            // Floats over the explanations so a session is one tap away at any scroll position.
            PrimaryActionButton(title: "technique.detail.startThisTechnique", tint: technique.tint) {
                onStart(technique)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .readableContentWidth(560)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            TechniqueOrb(technique: technique, size: 60)
                .padding(.bottom, 4)
            Text(technique.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(technique.purpose)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }
    #endif

    // MARK: Mac

    #if os(macOS)
    /// A document-style page: the start action sits in the header next to the name,
    /// where a Mac window's main action belongs, and the explanations use two
    /// columns when the window is wide enough.
    private var macBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                macHeader
                RhythmCard(technique: technique)

                if contentWidth >= 720 {
                    HStack(alignment: .top, spacing: 40) {
                        VStack(alignment: .leading, spacing: 28) {
                            macSection("technique.detail.howItWorks") { howItWorks }
                            macSection("technique.detail.bestFor") { bestFor }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        macSection("technique.detail.howToPractice") { howToPractice }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    macSection("technique.detail.howItWorks") { howItWorks }
                    macSection("technique.detail.bestFor") { bestFor }
                    macSection("technique.detail.howToPractice") { howToPractice }
                }

                Callout(text: technique.safetyNote, isSecondary: true)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .onGeometryChange(for: CGFloat.self) { $0.size.width - 64 } action: { contentWidth = $0 }
            .readableContentWidth(980)
        }
        .background(Theme.Palette.background)
    }

    private var macHeader: some View {
        HStack(spacing: 18) {
            TechniqueOrb(technique: technique, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(technique.name)
                    .font(.largeTitle.bold())
                Text(technique.purpose)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            Button {
                onStart(technique)
            } label: {
                Label("technique.detail.startThisTechnique", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(technique.tint)
            // Return starts the session.
            .keyboardShortcut(.defaultAction)
        }
    }

    private func macSection<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }
    #endif

    // MARK: Content

    private var howItWorks: some View {
        Text(technique.howItWorks)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bestFor: some View {
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

    private var howToPractice: some View {
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

/// The breathing rhythm at a glance: one tile per phase — the seconds large, the
/// phase below — and, after a divider, the session's length.
private struct RhythmCard: View {
    let technique: Technique

    var body: some View {
        HStack(spacing: 0) {
            ForEach(technique.phases.indices, id: \.self) { index in
                let phase = technique.phases[index]
                MetricTile(
                    value: phase.seconds,
                    unit: "technique.secondsUnit",
                    caption: phase.kind.title,
                    tint: technique.tint
                )
            }
            Divider()
                .frame(height: 44)
                .padding(.horizontal, 4)
            MetricTile(
                value: technique.recommendedDuration / 60,
                unit: "technique.minutesUnit",
                caption: String(localized: "technique.detail.session"),
                tint: .primary
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

/// A large number with its unit, and a caption underneath.
private struct MetricTile: View {
    let value: Int
    let unit: LocalizedStringKey
    let caption: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value, format: .number)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(unit)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(caption)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TechniqueDetailView(technique: TechniqueCatalog.all[0], onStart: { _ in })
    }
}
#endif
