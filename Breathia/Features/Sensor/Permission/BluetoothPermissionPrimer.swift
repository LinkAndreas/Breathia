import SwiftUI

/// Explains why Breathia needs Bluetooth before the system asks, so its
/// prompt never comes out of nowhere.
struct BluetoothPermissionPrimer: View {
    let isRequesting: Bool
    let onContinue: () -> Void

    var body: some View {
        Section {
            VStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(Color.red.gradient)
                        }
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.gradient, in: .circle)
                        .overlay(Circle().stroke(Theme.Palette.background, lineWidth: 3))
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("sensor.permission.title")
                        .font(.title3.bold())
                    Text("sensor.permission.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                // The lock sits beside the first line of the text, not off to the
                // side of a centred paragraph.
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "lock.fill")
                        .accessibilityHidden(true)
                    Text("sensor.permission.privacy")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    PrimaryActionButton(title: "sensor.permission.continue", tint: .blue, action: onContinue)
                        .disabled(isRequesting)
                        #if os(macOS)
                        .frame(maxWidth: 260)
                        #endif
                    Text("sensor.permission.next")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
            // Kept to a readable width in wide columns on iPad and Mac.
            .readableContentWidth(480)
        }
        .listRowBackground(Color.clear)
    }
}

#if DEBUG
#Preview {
    List {
        BluetoothPermissionPrimer(isRequesting: false, onContinue: {})
    }
}
#endif
