import CoreBluetooth

/// A GATT service to connect to, and the characteristics to subscribe to.
struct BluetoothService {
    let uuid: CBUUID
    let characteristicUUIDs: [CBUUID]
}

extension BluetoothService {
    /// The standard Heart Rate service (0x180D) and its measurement characteristic (0x2A37).
    static var heartRate: BluetoothService {
        BluetoothService(
            uuid: CBUUID(string: "180D"),
            characteristicUUIDs: [CBUUID(string: "2A37")]
        )
    }
}
