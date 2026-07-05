import Foundation
import Testing
@testable import MoleWidgetCore

@Suite struct UsageHistoryTests {
    private func sample(_ secondsAgo: TimeInterval, now: Date) -> UsageSample {
        UsageSample(
            timestamp: now.addingTimeInterval(-secondsAgo),
            cpuFraction: 0.5, memUsedBytes: 8_000_000_000, memTotalBytes: 16_000_000_000,
            topProcesses: []
        )
    }

    @Test func pruned_dropsOlderThanRetention() {
        let now = Date()
        let samples = [sample(90_000, now: now), sample(100, now: now)]
        let result = UsageHistoryMath.pruned(samples, now: now, retention: 86_400)
        #expect(result.count == 1)
        #expect(result[0].timestamp == samples[1].timestamp)
    }

    @Test func pruned_keepsBoundarySample() {
        let now = Date()
        let samples = [sample(86_400, now: now)]
        #expect(UsageHistoryMath.pruned(samples, now: now, retention: 86_400).count == 1)
    }

    @Test func pruned_emptyInput() {
        #expect(UsageHistoryMath.pruned([], now: Date()).isEmpty)
    }

    @Test func pruned_preservesOrder() {
        let now = Date()
        let samples = [sample(300, now: now), sample(200, now: now), sample(100, now: now)]
        let result = UsageHistoryMath.pruned(samples, now: now)
        #expect(result.map(\.timestamp) == samples.map(\.timestamp))
    }

    @Test func shouldRecord_nilLast_returnsTrue() {
        #expect(UsageHistoryMath.shouldRecord(lastAt: nil, now: Date(), interval: 60))
    }

    @Test func shouldRecord_belowInterval_returnsFalse() {
        let now = Date()
        #expect(!UsageHistoryMath.shouldRecord(lastAt: now.addingTimeInterval(-59), now: now, interval: 60))
    }

    @Test func shouldRecord_atInterval_returnsTrue() {
        let now = Date()
        #expect(UsageHistoryMath.shouldRecord(lastAt: now.addingTimeInterval(-60), now: now, interval: 60))
    }

    @Test func nearestSample_exactHit() {
        let now = Date()
        let samples = [sample(300, now: now), sample(100, now: now)]
        let target = samples[1].timestamp
        #expect(UsageHistoryMath.nearestSample(in: samples, to: target)?.timestamp == target)
    }

    @Test func nearestSample_betweenTwo() {
        let now = Date()
        let samples = [sample(300, now: now), sample(100, now: now)]
        // 110s ago is closer to the 100s-ago sample
        let probe = now.addingTimeInterval(-110)
        #expect(UsageHistoryMath.nearestSample(in: samples, to: probe)?.timestamp == samples[1].timestamp)
    }

    @Test func nearestSample_emptyReturnsNil() {
        #expect(UsageHistoryMath.nearestSample(in: [], to: Date()) == nil)
    }
}
