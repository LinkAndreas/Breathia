import Foundation

protocol BluetoothManagerDelegate: AnyObject {
    func manager(_ manager: BluetoothManager, didChangeStatus status: ConnectionStatus)
    func manager(_ manager: BluetoothManager, didReceive data: Data)
    func manager(_ manager: BluetoothManager, didEncounter error: Error)
}
