import SwiftUI

/// The Breathe section: a compact sensor status, then every technique grouped by
/// category, with native search and category filters. Tapping a technique opens
/// its details; the sensor is connected from the navigation bar.
struct BreatheHomeView: View {
    /// `true` on iPad, where the opened technique stays highlighted next to the
    /// detail column; `false` on iPhone, where rows push and show a chevron.
    let usesSelection: Bool
    let selectedTechniqueID: Technique.ID?
    let onOpen: (Technique.ID) -> Void
    let onShowSensor: () -> Void

    @State private var filter: TechniqueFilter = .all
    @State private var query = ""

    private var groups: [TechniqueGroup] {
        TechniqueGroup.grouping(
            TechniqueCatalog.all.filter { filter.includes($0) && $0.matches(query) }
        )
    }

    #if os(iOS)
    /// Tucked under the large title until the list is pulled down.
    private static let searchPlacement = SearchFieldPlacement.navigationBarDrawer(displayMode: .automatic)
    #else
    /// In the column's toolbar.
    private static let searchPlacement = SearchFieldPlacement.toolbar
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TechniqueFilterBar(selection: $filter)
                    .padding(.top, 8)

                // Changing the filter crossfades the whole list rather than animating
                // each row into place; the ZStack overlaps outgoing and incoming lists
                // so neither pushes the other down. Search results update instantly.
                ZStack(alignment: .top) {
                    techniqueList
                        .id(filter)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Theme.Palette.background)
        .navigationTitle("common.breathe")
        #if os(macOS)
        // A Mac window has one title, taken from this column; the open technique
        // shows as its subtitle, as the selected mailbox's details do in Mail.
        .navigationSubtitle(selectedTechniqueID.map { TechniqueCatalog.technique(withID: $0).name } ?? "")
        #endif
        .searchable(text: $query, placement: Self.searchPlacement, prompt: Text("breathe.searchTechniques"))
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SensorToolbarWidget(action: onShowSensor)
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }

    private var techniqueList: some View {
        VStack(spacing: 0) {
            ForEach(groups) { group in
                // A single chosen category needs no header of its own.
                if filter == .all {
                    TechniqueCategoryHeader(category: group.category)
                }
                LazyVStack(spacing: 10) {
                    ForEach(group.techniques) { technique in
                        TechniqueRow(
                            technique: technique,
                            isSelected: usesSelection && technique.id == selectedTechniqueID,
                            showsDisclosure: !usesSelection
                        ) {
                            onOpen(technique.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, filter == .all ? 0 : 12)
            }
        }
    }
}

/// The sensor's state as a navigation bar widget, and the way to connect it:
/// the sensor symbol and "HR Sensor" while disconnected, progress while searching or connecting, and —
/// once a sensor is connected — a green, filled capsule with the live heart rate,
/// so a connected sensor is obvious at a glance. Tapping it opens the sensor sheet.
private struct SensorToolbarWidget: View {
    let action: () -> Void

    @Environment(HeartRateMonitor.self) private var monitor

    var body: some View {
        if monitor.isConnected {
            button
                .buttonStyle(.glassProminent)
                .tint(Theme.Palette.connected)
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                icon
                label
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            #if os(iOS)
            .font(.subheadline.weight(.semibold))
            #else
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            #endif
            .animation(.snappy, value: monitor.heartRate)
            .animation(.snappy, value: monitor.status)
        }
        .accessibilityLabel(Text("common.heartRateSensor"))
        .accessibilityValue(Text(monitor.statusDetail))
        .accessibilityHint(Text("breathe.opensHeartRateSensor"))
    }

    @ViewBuilder
    private var icon: some View {
        switch monitor.status {
        case .connected:
            Image(systemName: "heart.fill")
                .symbolEffect(.pulse, isActive: monitor.heartRate != nil)
        case .scanning, .connecting, .reconnecting, .disconnecting:
            ProgressView()
                .controlSize(.small)
        case .idle, .failed, .unavailable, .needsPermission, .denied:
            // The sensor symbol; the heart appears once a sensor is connected.
            Image(systemName: "antenna.radiowaves.left.and.right")
        }
    }

    @ViewBuilder
    private var label: some View {
        switch monitor.status {
        case .connected:
            if let heartRate = monitor.heartRate {
                Text("common.bpm \(heartRate)")
            } else {
                Text(monitor.status.summary)
            }
        case .scanning, .connecting, .reconnecting, .disconnecting:
            Text(monitor.status.summary)
        case .idle, .failed, .unavailable, .needsPermission, .denied:
            Text("breathe.hrSensor", comment: "Short label of the heart-rate sensor button while none is connected")
        }
    }
}

private struct TechniqueRow: View {
    let technique: Technique
    let isSelected: Bool
    let showsDisclosure: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                TechniqueOrb(technique: technique, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(technique.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(verbatim: "\(technique.patternLabel) · \(technique.durationLabel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showsDisclosure {
                    DisclosureChevron()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.Palette.elevated, in: .rect(cornerRadius: Theme.Radius.row))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.row)
                    .strokeBorder(isSelected ? technique.tint : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.row))
        }
        .buttonStyle(.plain)
        #if os(iOS)
        // Highlights the card under the pointer on iPad.
        .hoverEffect(.highlight)
        #endif
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        BreatheHomeView(usesSelection: false, selectedTechniqueID: nil, onOpen: { _ in }, onShowSensor: {})
    }
    .environment(PreviewStores.heartRateMonitor())
}
#endif
