import Foundation
import Testing
@testable import MoleWidgetCore

@Suite struct DiskTests {
    @Test func ratesFromCounterDeltas() {
        let prev = DiskIOCounters(bytesRead: 1000, bytesWritten: 2000)
        let cur = DiskIOCounters(bytesRead: 1000 + 2_097_152, bytesWritten: 2000 + 1_048_576)
        let rates = DiskIO.rates(previous: prev, current: cur, interval: 2.0)
        #expect(abs(rates.read - 1_048_576) < 0.1)  // 1 MiB/s
        #expect(abs(rates.write - 524_288) < 0.1)   // 0.5 MiB/s
    }

    @Test func ratesWithZeroIntervalAreZero() {
        let counters = DiskIOCounters(bytesRead: 100, bytesWritten: 100)
        let rates = DiskIO.rates(previous: counters, current: counters, interval: 0)
        #expect(rates.read == 0)
        #expect(rates.write == 0)
    }

    @Test func usageOfRootVolume() throws {
        let snap = try #require(DiskCollector().usage())
        #expect(snap.total > 10_000_000_000) // disk is larger than 10 GB
        #expect(snap.free > 0)
        #expect(snap.free < snap.total)
        #expect(snap.fileSystem == "APFS")
        #expect((0...1).contains(snap.usedFraction))
    }

    @Test func ioCountersAreCumulative() throws {
        let collector = DiskCollector()
        let first = try #require(collector.ioCounters())
        #expect(first.bytesRead > 0)
        Thread.sleep(forTimeInterval: 0.3)
        let second = try #require(collector.ioCounters())
        #expect(second.bytesRead >= first.bytesRead)
        #expect(second.bytesWritten >= first.bytesWritten)
    }

    @Test func ratesIgnoreCounterReset() {
        let prev = DiskIOCounters(bytesRead: 5000, bytesWritten: 5000)
        let cur = DiskIOCounters(bytesRead: 100, bytesWritten: 6000) // read counter reset
        let rates = DiskIO.rates(previous: prev, current: cur, interval: 1.0)
        #expect(rates.read == 0)
        #expect(rates.write == 1000)
    }
}
