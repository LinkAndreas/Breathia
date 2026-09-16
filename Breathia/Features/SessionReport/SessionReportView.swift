import SwiftUI

/// The cards describing a finished session — shared by the results screen and
/// the History detail screen.
struct SessionReportView: View {
    let session: SessionRecord

    var body: some View {
        VStack(spacing: 20) {
            if let heartRate = session.heartRate {
                HeartRateSummaryCard(stats: heartRate, trace: session.heartRateTrace, tint: session.technique.tint)
            } else {
                NoSensorDataCard()
            }

            if let hrv = session.hrv {
                HRVSummaryCard(stats: hrv)
            }

            Pill(text: session.technique.patternLabel, tint: session.technique.tint)

            Callout(text: session.summaryText)
        }
    }
}

private struct HeartRateSummaryCard: View {
    let stats: HeartRateStats
    let trace: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("common.heartRate")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                stat("common.start", stats.start)
                stat("report.average", stats.average)
                stat("common.end", stats.end)
            }
            .padding(.bottom, 10)

            TrendSparkline(values: trace, tint: tint)
        }
        .cardSurface(verticalPadding: 14)
    }

    private func stat(_ label: LocalizedStringKey, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct HRVSummaryCard: View {
    let stats: HRVStats

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stats.metric.title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Text("report.milliseconds \(Int(stats.average.rounded()))")
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
                Spacer()
                if let trend = stats.trend {
                    Text(trend.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trend.color, in: .capsule)
                }
            }
        }
        .cardSurface(verticalPadding: 14)
    }
}

private struct NoSensorDataCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("report.noSensorData")
                .font(.headline)
            Text("report.polarH10WasntConnected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

extension HRVTrend {
    var title: String {
        switch self {
        case .increasing: String(localized: "report.increasing", comment: "HRV trend")
        case .stable: String(localized: "report.stable", comment: "HRV trend")
        case .decreasing: String(localized: "report.decreasing", comment: "HRV trend")
        }
    }

    var shortLabel: String {
        switch self {
        case .increasing: String(localized: "report.hrvTrendUp")
        case .stable: String(localized: "report.hrvTrendSteady")
        case .decreasing: String(localized: "report.hrvTrendDown")
        }
    }

    var color: Color {
        switch self {
        case .increasing: .green
        case .stable: .secondary
        case .decreasing: Theme.Palette.tertiaryLabel
        }
    }
}

extension SessionRecord {
    var summaryText: String {
        guard hasSensorData else {
            return String(localized: "report.sessionsWithoutASensor")
        }
        return switch hrv?.trend {
        case .increasing: String(localized: "report.yourHRVRose")
        case .stable: String(localized: "report.yourHRVStayedFairly")
        case .decreasing: String(localized: "report.yourHRVDippedSlightly")
        case nil: String(localized: "report.theSessionWasToo")
        }
    }
}
