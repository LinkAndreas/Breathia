import Foundation

/// The sensor model the app is built for. Found sensors of this model are listed first.
enum BluetoothDevice {
    case polarH10

    var name: String {
        switch self {
        case .polarH10: "Polar H10"
        }
    }
}
