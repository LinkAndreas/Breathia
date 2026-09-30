import SwiftUI

/// Live heart rate and HRV side by side, while a sensor is connected.
struct LiveMetrics: View {
    let model: BreathingSessionModel

    var body: some View {
        if model.isSensorConnected {
            HStack(spacing: 10) {
                LiveMetricCard(
                    value: average(of: model.recentHeartRates).map { String(localized: "session.bpmAvg \($0)") } ?? "—",
                    label: "common.heartRate",
                    values: model.recentHeartRates,
                    tint: model.technique.tint
                )
                LiveMetricCard(
                    value: average(of: model.recentHRV).map { String(localized: "session.msAvg \($0)") } ?? "—",
                    label: "session.hrv \(model.hrvMetric.title)",
                    values: model.recentHRV,
                    tint: .green
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    private func average(of values: [Double]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((values.reduce(0, +) / Double(values.count)).rounded())
    }
}

#if DEBUG
#Preview {
    LiveMetrics(model: PreviewStores.sessionFactory().makeSession(for: TechniqueCatalog.all[1]))
}
#endif
