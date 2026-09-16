import Foundation

/// Decodes the Bluetooth Heart Rate Measurement characteristic (0x2A37).
enum MeasurementParser {
    /// Returns `nil` for a packet too short to hold what its flags announce, so a
    /// malformed notification is dropped instead of crashing the app.
    nonisolated static func parse(_ data: Data) -> HeartRateMeasurement? {
        let bytes = [UInt8](data)
        guard let flags = bytes.first else { return nil }

        let heartRateIs16Bit = flags & 0x01 != 0
        // Sensor contact: bit 2 says the sensor reports it, bit 1 whether there is contact.
        let reportsContact = flags & 0x04 != 0
        let hasContact = flags & 0x02 != 0
        let energyExpendedPresent = flags & 0x08 != 0
        let rrIntervalsPresent = flags & 0x10 != 0

        var index = 1
        let heartRate: Int
        if heartRateIs16Bit {
            guard bytes.count >= index + 2 else { return nil }
            heartRate = Int(bytes[index]) | Int(bytes[index + 1]) << 8
            index += 2
        } else {
            guard bytes.count >= index + 1 else { return nil }
            heartRate = Int(bytes[index])
            index += 1
        }

        if energyExpendedPresent {
            index += 2 // Not used.
        }

        var rrIntervals: [Double] = []
        if rrIntervalsPresent {
            while index + 1 < bytes.count {
                let raw = UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
                // The spec's unit is 1/1024 s; convert to milliseconds.
                rrIntervals.append(Double(raw) / 1024 * 1000)
                index += 2
            }
        }

        return HeartRateMeasurement(
            heartRate: heartRate,
            rrIntervals: rrIntervals,
            hasSkinContact: !reportsContact || hasContact
        )
    }
}
