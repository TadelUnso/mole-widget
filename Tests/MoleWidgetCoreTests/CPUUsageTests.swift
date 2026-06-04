import Testing
@testable import MoleWidgetCore

@Suite struct CPUUsageTests {
    // Core 0: deltas user 100, system 50, idle 850 → busy 150 / total 1000 = 0.15
    // Core 1: deltas user 500, system 250, idle 250 → busy 750 / total 1000 = 0.75
    let prev = CPUSample(cores: [
        CoreTicks(user: 100, system: 50, idle: 850, nice: 0),
        CoreTicks(user: 0, system: 0, idle: 0, nice: 0),
    ])
    let cur = CPUSample(cores: [
        CoreTicks(user: 200, system: 100, idle: 1700, nice: 0),
        CoreTicks(user: 500, system: 250, idle: 250, nice: 0),
    ])

    @Test func perCore() {
        let usages = CPUUsage.perCore(previous: prev, current: cur)
        #expect(usages.count == 2)
        #expect(abs(usages[0] - 0.15) < 0.001)
        #expect(abs(usages[1] - 0.75) < 0.001)
    }

    @Test func perCoreZeroDeltaGivesZero() {
        #expect(CPUUsage.perCore(previous: prev, current: prev) == [0, 0])
    }

    @Test func totalAggregatesAllCores() {
        // busy 150+750 = 900, total 1000+1000 = 2000 → 0.45
        #expect(abs(CPUUsage.total(previous: prev, current: cur) - 0.45) < 0.001)
    }

    @Test func topCoresSortedDescending() {
        let top = CPUUsage.topCores([0.15, 0.75], count: 3)
        #expect(top == [CoreUsage(index: 1, usage: 0.75), CoreUsage(index: 0, usage: 0.15)])
    }

    @Test func topCoresLimitsCount() {
        let top = CPUUsage.topCores([0.1, 0.2, 0.3, 0.4], count: 2)
        #expect(top == [CoreUsage(index: 3, usage: 0.4), CoreUsage(index: 2, usage: 0.3)])
    }

    @Test func snapshotComposition() {
        let snap = CPUUsage.snapshot(previous: prev, current: cur, loadAverage: [1.83, 1.70, 2.07])
        #expect(abs(snap.totalUsage - 0.45) < 0.001)
        #expect(snap.topCores.first == CoreUsage(index: 1, usage: 0.75))
        #expect(snap.loadAverage == [1.83, 1.70, 2.07])
        #expect(snap.coreCount == 2)
        #expect(snap.topCores.count == 2)
    }

    @Test func emptySamples() {
        let empty = CPUSample(cores: [])
        #expect(CPUUsage.perCore(previous: empty, current: empty) == [])
        #expect(CPUUsage.total(previous: empty, current: empty) == 0)
        #expect(CPUUsage.topCores([], count: 3) == [])
    }

    @Test func topCoresStableOrderOnTies() {
        let top = CPUUsage.topCores([0.5, 0.5, 0.2], count: 2)
        #expect(top == [CoreUsage(index: 0, usage: 0.5), CoreUsage(index: 1, usage: 0.5)])
    }

    @Test func perCoreClampsKernelAnomalies() {
        // busy delta (200) exceeds total delta (100) — tick rollback anomaly → clamped to 1.0
        let prev = CPUSample(cores: [CoreTicks(user: 0, system: 0, idle: 100, nice: 0)])
        let cur = CPUSample(cores: [CoreTicks(user: 200, system: 0, idle: 0, nice: 0)])
        #expect(CPUUsage.perCore(previous: prev, current: cur) == [1.0])
        #expect(CPUUsage.total(previous: prev, current: cur) == 1.0)
    }
}
