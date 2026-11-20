import SwiftUI

/// Sets how loud the breathing cues play, on top of the device volume. Letting go
/// of the slider plays a cue at the new volume.
struct CueVolumeSlider: View {
    @Binding var volume: Double
    let onEditingEnded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsLabel("settings.cueVolume", systemImage: "speaker.wave.2.fill", color: .indigo)
            Slider(value: $volume, in: 0...1) {
                Text("settings.cueVolume")
            } minimumValueLabel: {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            } onEditingChanged: { isEditing in
                if !isEditing { onEditingEnded() }
            }
            .accessibilityValue(Text(volume, format: .percent.precision(.fractionLength(0))))
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var volume = 0.8
    Form {
        CueVolumeSlider(volume: $volume, onEditingEnded: {})
    }
}
#endif
