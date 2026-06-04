import Testing
@testable import MoleWidgetCore

@Suite struct MetricsStoreTests {
    @MainActor
    @Test func refreshPopulatesSnapshots() async throws {
        let store = MetricsStore()

        // First CPU sample only records ticks — cpu is still nil
        store.refreshFast()
        #expect(store.cpu == nil)
        #expect(store.memory != nil)

        try await Task.sleep(for: .milliseconds(10))
        store.refreshFast()
        #expect(store.cpu != nil)
        #expect(store.diskIO != nil)

        store.refreshDiskUsage()
        #expect(store.diskUsage != nil)

        // Power may be nil on a Mac without a battery — must not crash
        store.refreshPower()
    }

    @MainActor
    @Test func startStopDoesNotCrashAndIsIdempotent() {
        let store = MetricsStore()
        store.start()
        store.start() // repeated start must not duplicate timers
        store.stop()
        store.stop() // repeated stop is a no-op
        #expect(store.memory != nil) // start() performs an initial refresh
    }
}
