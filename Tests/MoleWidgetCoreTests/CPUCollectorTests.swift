import Foundation
import Testing
@testable import MoleWidgetCore

@Suite struct CPUCollectorTests {
    @Test func sampleTicksReturnsCores() throws {
        let sample = try #require(CPUCollector().sampleTicks())
        #expect(sample.cores.count > 0)
        #expect(sample.cores[0].total > 0)
    }

    @Test func loadAverageHasThreeNonNegativeValues() {
        let loads = CPUCollector().loadAverage()
        #expect(loads.count == 3)
        #expect(loads.allSatisfy { $0 >= 0 })
    }

    @Test func usageBetweenTwoSamplesIsInRange() throws {
        let collector = CPUCollector()
        let first = try #require(collector.sampleTicks())
        Thread.sleep(forTimeInterval: 0.5)
        let second = try #require(collector.sampleTicks())
        let usages = CPUUsage.perCore(previous: first, current: second)
        #expect(usages.count == first.cores.count)
        #expect(usages.allSatisfy { (0...1).contains($0) })
    }
}
