import Testing
@testable import MoleWidgetCore

@Suite struct MemoryTests {
    @Test func computeFromRawCounts() {
        // pageSize 4096, total 10_000 pages = 40_960_000 bytes
        let stats = VMStats(
            free: 1000, active: 2000, inactive: 500, wired: 1000,
            compressed: 500, purgeable: 200, external: 300, speculative: 0
        )
        let snap = MemoryUsage.compute(stats: stats, pageSize: 4096, total: 40_960_000)
        // used = (active 2000 + wired 1000 + compressed 500) * 4096
        #expect(snap.used == 14_336_000)
        // free = total - used
        #expect(snap.free == 26_624_000)
        // cached = (purgeable 200 + external 300) * 4096
        #expect(snap.cached == 2_048_000)
        // available = free_count * pageSize + cached
        #expect(snap.available == 6_144_000)
        #expect(abs(snap.usedFraction - 0.35) < 0.001)
        #expect(abs(snap.freeFraction - 0.65) < 0.001)
    }

    @Test func computeWithZeroTotalDoesNotCrash() {
        let stats = VMStats(free: 0, active: 0, inactive: 0, wired: 0,
                            compressed: 0, purgeable: 0, external: 0, speculative: 0)
        let snap = MemoryUsage.compute(stats: stats, pageSize: 4096, total: 0)
        #expect(snap.usedFraction == 0)
        #expect(snap.freeFraction == 0)
    }

    @Test func collectorReturnsSaneValues() throws {
        let snap = try #require(MemoryCollector().sample())
        #expect(snap.total > 1_000_000_000) // any Mac has more than 1 GB
        #expect(snap.used > 0)
        #expect(snap.used <= snap.total)
        #expect(snap.used + snap.free == snap.total)
        #expect((0...1).contains(snap.usedFraction))
    }
}
