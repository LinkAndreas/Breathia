import Foundation
import Testing
@testable import Breathia

struct MeasurementParserTests {
    @Test func parsesEightBitHeartRateWithRRIntervals() throws {
        // Flags: RR present (0x10), contact supported and detected (0x06).
        let measurement = try #require(MeasurementParser.parse(Data([0x16, 72, 0x00, 0x04])))
        #expect(measurement.heartRate == 72)
        #expect(measurement.rrIntervals == [1000])
        #expect(measurement.hasSkinContact)
        #expect(measurement.isValid)
    }

    @Test func parsesSixteenBitHeartRate() throws {
        let measurement = try #require(MeasurementParser.parse(Data([0x01, 0x2C, 0x01])))
        #expect(measurement.heartRate == 300)
    }

    @Test func skipsEnergyExpended() throws {
        let measurement = try #require(MeasurementParser.parse(Data([0x18, 60, 0xFF, 0xFF, 0x00, 0x02])))
        #expect(measurement.rrIntervals == [500])
    }

    @Test func reportsLostSkinContact() throws {
        // Contact supported (0x04) but not detected.
        let measurement = try #require(MeasurementParser.parse(Data([0x04, 0])))
        #expect(!measurement.hasSkinContact)
        #expect(!measurement.isValid)
    }

    @Test func treatsSensorsWithoutContactReportingAsInContact() throws {
        let measurement = try #require(MeasurementParser.parse(Data([0x00, 64])))
        #expect(measurement.hasSkinContact)
    }

    @Test func rejectsAZeroHeartRate() throws {
        let measurement = try #require(MeasurementParser.parse(Data([0x06, 0])))
        #expect(!measurement.isValid)
    }

    @Test func dropsMalformedPackets() {
        #expect(MeasurementParser.parse(Data()) == nil)
        #expect(MeasurementParser.parse(Data([0x01, 0x2C])) == nil)
    }
}
