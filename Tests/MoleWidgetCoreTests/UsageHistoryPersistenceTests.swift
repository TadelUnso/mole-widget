import Foundation
import Testing
@testable import MoleWidgetCore

@Suite struct UsageHistoryPersistenceTests {
    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("UsageHistoryTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func sample(_ i: Int) -> UsageSample {
        UsageSample(
            timestamp: Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + i * 60)),
            cpuFraction: Double(i) / 100.0,
            memUsedBytes: UInt64(i) * 1_000_000_000,
            memTotalBytes: 16_000_000_000,
            topProcesses: [UsageProcess(pid: Int32(i), name: "proc\(i)", cpuFraction: 0.1, memoryBytes: 500_000_000)]
        )
    }

    @Test func appendThenLoadRoundTrips() {
        let store = UsageHistoryPersistence(directory: tempDir())
        let samples = (0..<5).map(sample)
        samples.forEach(store.append)
        #expect(store.loadAll() == samples)
    }

    @Test func corruptLineIsSkipped() throws {
        let dir = tempDir()
        let store = UsageHistoryPersistence(directory: dir)
        store.append(sample(1))
        // Inject a garbage line in the middle.
        let file = dir.appendingPathComponent("usage-history.jsonl")
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("not json\n".utf8))
        try handle.close()
        store.append(sample(2))

        let loaded = store.loadAll()
        #expect(loaded.count == 2)
        #expect(loaded.map(\.timestamp) == [sample(1).timestamp, sample(2).timestamp])
    }

    @Test func rewriteProducesLoadableFile() {
        let store = UsageHistoryPersistence(directory: tempDir())
        (0..<10).map(sample).forEach(store.append)
        let kept = (5..<10).map(sample)
        store.rewrite(kept)
        #expect(store.loadAll() == kept)
    }

    @Test func loadFromMissingFileReturnsEmpty() {
        let store = UsageHistoryPersistence(directory: tempDir())
        #expect(store.loadAll().isEmpty)
    }
}
