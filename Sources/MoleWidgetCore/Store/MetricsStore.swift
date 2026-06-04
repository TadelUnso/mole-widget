import Foundation
import Observation

/// Central snapshot store. Polls collectors on timers at different frequencies
/// and publishes the results for SwiftUI.
@MainActor
@Observable
public final class MetricsStore {
    public private(set) var cpu: CPUSnapshot?
    public private(set) var memory: MemorySnapshot?
    public private(set) var diskUsage: DiskUsageSnapshot?
    public private(set) var diskIO: DiskIORates?
    public private(set) var power: PowerSnapshot?

    @ObservationIgnored private let cpuCollector = CPUCollector()
    @ObservationIgnored private let memoryCollector = MemoryCollector()
    @ObservationIgnored private let diskCollector = DiskCollector()
    @ObservationIgnored private let powerCollector = PowerCollector()

    @ObservationIgnored private var previousCPU: CPUSample?
    @ObservationIgnored private var previousIO: (counters: DiskIOCounters, at: Date)?
    @ObservationIgnored private var timers: [Timer] = []

    public init() {}

    deinit {
        timers.forEach { $0.invalidate() }
    }

    public func start() {
        stop() // a repeated start() must not leave stale timers in the RunLoop
        refreshFast()
        refreshDiskUsage()
        refreshPower()
        timers = [
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refreshFast() }
            },
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refreshDiskUsage() }
            },
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refreshPower() }
            },
        ]
    }

    public func stop() {
        timers.forEach { $0.invalidate() }
        timers = []
    }

    /// CPU + Memory + Disk I/O — every 2 seconds.
    public func refreshFast() {
        if let ticks = cpuCollector.sampleTicks() {
            if let prev = previousCPU {
                cpu = CPUUsage.snapshot(
                    previous: prev,
                    current: ticks,
                    loadAverage: cpuCollector.loadAverage()
                )
            }
            previousCPU = ticks
        }
        if let mem = memoryCollector.sample() {
            memory = mem
        }
        if let counters = diskCollector.ioCounters() {
            let now = Date()
            if let prev = previousIO {
                diskIO = DiskIO.rates(
                    previous: prev.counters,
                    current: counters,
                    interval: now.timeIntervalSince(prev.at)
                )
            }
            previousIO = (counters, now)
        } else {
            previousIO = nil // IOKit failure → next sample pair starts fresh
        }
    }

    /// Disk usage — every 60 seconds (changes slowly).
    public func refreshDiskUsage() {
        if let usage = diskCollector.usage() {
            diskUsage = usage
        }
    }

    /// Battery — every 30 seconds. nil = "No data" (Mac without a battery).
    public func refreshPower() {
        power = powerCollector.sample()
    }
}
