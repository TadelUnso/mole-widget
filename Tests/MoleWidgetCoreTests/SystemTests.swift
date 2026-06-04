import Testing
@testable import MoleWidgetCore

// MARK: - HealthScore tests

@Suite struct HealthScoreTests {
    // All nil inputs → score stays at 100 (no penalties)
    @Test func allNilReturns100() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 100)
    }

    // cpu > 0.8 → −15 (100 − 15 = 85)
    @Test func cpuPenalty() {
        let score = HealthScore.compute(
            cpu: 0.81,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 85)
    }

    // cpu == 0.8 is the boundary — NOT penalized (100)
    @Test func cpuBoundaryNotPenalized() {
        let score = HealthScore.compute(
            cpu: 0.8,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 100)
    }

    // memUsedFraction > 0.85 → −15 (100 − 15 = 85)
    @Test func memPenalty() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: 0.86,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 85)
    }

    // diskUsedFraction > 0.9 → −20 (100 − 20 = 80)
    @Test func diskPenalty() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: nil,
            diskUsedFraction: 0.91,
            batteryHealth: nil,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 80)
    }

    // batteryHealth < 0.8 → −10 (100 − 10 = 90)
    @Test func batteryHealthPenalty() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: 0.79,
            batteryLevel: nil,
            isCharging: false
        )
        #expect(score == 90)
    }

    // batteryLevel < 0.15 && !isCharging → −10 (100 − 10 = 90)
    @Test func lowBatteryNotChargingPenalty() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: 0.14,
            isCharging: false
        )
        #expect(score == 90)
    }

    // batteryLevel < 0.15 but isCharging → no penalty (100)
    @Test func lowBatteryChargingNoPenalty() {
        let score = HealthScore.compute(
            cpu: nil,
            memUsedFraction: nil,
            diskUsedFraction: nil,
            batteryHealth: nil,
            batteryLevel: 0.14,
            isCharging: true
        )
        #expect(score == 100)
    }

    // All bad: −15 −15 −20 −10 −10 = −70 → 30
    @Test func allBadReturns30() {
        let score = HealthScore.compute(
            cpu: 0.9,
            memUsedFraction: 0.9,
            diskUsedFraction: 0.95,
            batteryHealth: 0.5,
            batteryLevel: 0.1,
            isCharging: false
        )
        #expect(score == 30)
    }
}

// MARK: - SystemInfoSnapshot uptime formatter tests

@Suite struct UptimeFormatterTests {
    // Under 1 hour → "up 36m"
    @Test func under1HourShowsMinutes() {
        #expect(SystemInfoSnapshot.formatUptime(36 * 60) == "up 36m")
    }

    // 1h...24h → "up 5h 36m"
    @Test func between1And24HoursShowsHoursAndMinutes() {
        #expect(SystemInfoSnapshot.formatUptime(5 * 3600 + 36 * 60) == "up 5h 36m")
    }

    // ≥ 24h → "up 3d 4h"
    @Test func over24HoursShowsDaysAndHours() {
        #expect(SystemInfoSnapshot.formatUptime(3 * 86400 + 4 * 3600) == "up 3d 4h")
    }

    // Smoke: SystemInfoCollector returns valid data from real hardware
    @Test func smokeCollectorReturnsValidSnapshot() {
        let collector = SystemInfoCollector()
        guard let snap = collector.sample() else {
            Issue.record("SystemInfoCollector.sample() returned nil")
            return
        }
        #expect(!snap.chip.isEmpty)
        #expect(snap.ramBytes > 1_000_000_000)
        #expect(snap.uptime > 0)
    }
}
