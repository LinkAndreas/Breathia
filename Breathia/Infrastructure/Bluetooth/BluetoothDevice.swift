import Foundation

/// The sensor model the app is designed around. Any sensor offering the standard
/// Heart Rate service pairs; found sensors of this model are just listed first.
enum BluetoothDevice {
    case polarH10

    var name: String {
        switch self {
        case .polarH10: "Polar H10"
        }
    }
}
