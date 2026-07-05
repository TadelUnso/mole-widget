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
    public private(set) var cpuTemperature: Double?
    public private(set) var netRates: NetIORates?
    public private(set) var networkInfo: NetworkInfo?
    public private(set) var topProcesses: [ProcessUsage] = []
    public private(set) var systemInfo: SystemInfoSnapshot?
    public private(set) var healthScore: Int = 100
    public private(set) var cpuHistory = History()
    public private(set) var netInHistory = History()
    public private(set) var netOutHistory = History()

    @ObservationIgnored private let cpuCollector = CPUCollector()
    @ObservationIgnored private let memoryCollector = MemoryCollector()
    @ObservationIgnored private let diskCollector = DiskCollector()
    @ObservationIgnored private let powerCollector = PowerCollector()
    @ObservationIgnored private let networkCollector = NetworkCollector()
    @ObservationIgnored private let processCollector = ProcessCollector()
    @ObservationIgnored private let systemInfoCollector = SystemInfoCollector()
    @ObservationIgnored private let smcTemperature = SMCTemperature()

    @ObservationIgnored private var previousCPU: CPUSample?
    @ObservationIgnored private var previousIO: (counters: DiskIOCounters, at: Date)?
    @ObservationIgnored private var previousNetIO: (counters: NetIOCounters, at: Date)?
    @ObservationIgnored private var previousProcs: (samples: [ProcSample], at: Date)?
    @ObservationIgnored private var timers: [Timer] = []

    public init() {}

    deinit {
        timers.forEach { $0.invalidate() }
    }

    public func start() {
        stop() // a repeated start() must not leave stale timers in the RunLoop
        refreshFast()
        refreshProcesses()
        refreshDiskUsage()
        refreshPower()
        networkInfo = networkCollector.info()
        systemInfo = systemInfoCollector.sample()
        // Read the fast-timer interval from user defaults; floor at 1 s.
        let interval = max(
            1.0,
            UserDefaults.standard.object(forKey: WidgetSettings.refreshIntervalKey) as? Double
                ?? WidgetSettings.defaultRefreshInterval
        )
        timers = [
            makeTimer(interval, tolerance: interval * 0.2) { $0.refreshFast() },
            makeTimer(5, tolerance: 1) { $0.refreshProcesses() },
            makeTimer(60, tolerance: 15) { $0.refreshDiskUsage() },
            makeTimer(30, tolerance: 8) { $0.refreshPower() },
        ]
    }

    /// Repeating timer with a wake-up tolerance so macOS can coalesce it with
    /// other timers — fewer wake-ups means noticeably lower energy use than
    /// forcing the system awake precisely on every interval.
    private func makeTimer(
        _ interval: TimeInterval,
        tolerance: TimeInterval,
        _ body: @escaping (MetricsStore) -> Void
    ) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in if let self { body(self) } }
        }
        timer.tolerance = tolerance
        return timer
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
                if let snapshot = cpu {
                    cpuHistory.push(snapshot.totalUsage)
                }
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
        if let counters = networkCollector.ioCounters() {
            let now = Date()
            if let prev = previousNetIO {
                let rates = NetIO.rates(
                    previous: prev.counters,
                    current: counters,
                    interval: now.timeIntervalSince(prev.at)
                )
                netRates = rates
                netInHistory.push(rates.download)
                netOutHistory.push(rates.upload)
            }
            previousNetIO = (counters, now)
        } else {
            previousNetIO = nil // getifaddrs failure → next sample pair starts fresh
        }
        healthScore = HealthScore.compute(
            cpu: cpu?.totalUsage,
            memUsedFraction: memory?.usedFraction,
            diskUsedFraction: diskUsage?.usedFraction,
            batteryHealth: power?.healthFraction,
            batteryLevel: power?.levelFraction,
            isCharging: power?.isCharging ?? false
        )
    }

    /// Top processes — every 5 seconds. Enumerating every pid
    /// (`proc_listallpids` + `proc_pid_rusage`/`proc_name` per pid) is the most
    /// expensive sample, and the "top processes" list does not need sub-second
    /// freshness, so it runs on its own slower timer instead of the fast tick.
    public func refreshProcesses() {
        let procSamples = processCollector.sample()
        if !procSamples.isEmpty {
            let now = Date()
            if let prev = previousProcs {
                topProcesses = ProcessMath.top(
                    previous: prev.samples,
                    current: procSamples,
                    interval: now.timeIntervalSince(prev.at)
                )
            }
            previousProcs = (procSamples, now)
        } else {
            previousProcs = nil // collection failure → next sample pair starts fresh
        }
    }

    /// Disk usage — every 60 seconds (changes slowly).
    public func refreshDiskUsage() {
        if let usage = diskCollector.usage() {
            diskUsage = usage
        }
    }

    /// Battery + network interface info + system info — every 30 seconds.
    public func refreshPower() {
        power = powerCollector.sample()
        cpuTemperature = smcTemperature.cpuTemperature()
        networkInfo = networkCollector.info()
        systemInfo = systemInfoCollector.sample()
    }
}
