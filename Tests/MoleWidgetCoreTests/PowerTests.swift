import Testing
@testable import MoleWidgetCore

@Suite struct PowerTests {
    @Test func healthFraction() {
        #expect(BatteryMath.health(rawMaxCapacity: 8000, designCapacity: 8000) == 1.0)
        #expect(abs(BatteryMath.health(rawMaxCapacity: 7000, designCapacity: 8000)! - 0.875) < 0.001)
        #expect(BatteryMath.health(rawMaxCapacity: 8000, designCapacity: 0) == nil)
        // Health cannot exceed 100% (new batteries sometimes report raw > design)
        #expect(BatteryMath.health(rawMaxCapacity: 8200, designCapacity: 8000) == 1.0)
    }

    @Test func celsiusFromRawTemperature() {
        #expect(abs(BatteryMath.celsius(fromRawTemperature: 3020) - 30.2) < 0.001)
        #expect(BatteryMath.celsius(fromRawTemperature: 0) == 0)
    }

    @Test func formatMinutes() {
        #expect(BatteryMath.formatMinutes(411) == "6:51")
        #expect(BatteryMath.formatMinutes(60) == "1:00")
        #expect(BatteryMath.formatMinutes(5) == "0:05")
        #expect(BatteryMath.formatMinutes(0) == "0:00")
        #expect(BatteryMath.formatMinutes(-5) == "0:00")
    }

    @Test func collectorOnBatteryMac() {
        guard let snap = PowerCollector().sample() else {
            return // Mac without a battery — nothing to check
        }
        #expect((0...1).contains(snap.levelFraction))
        if let health = snap.healthFraction {
            #expect((0...1).contains(health))
        }
        if let cycles = snap.cycleCount {
            #expect(cycles >= 0)
        }
        if let t = snap.temperatureCelsius {
            #expect((0...80).contains(t))
        }
    }
}
