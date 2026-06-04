/// Raw ticks for a single core from host_processor_info (monotonically increasing).
public struct CoreTicks: Equatable {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    var busy: UInt64 { user &+ system &+ nice }
    var total: UInt64 { user &+ system &+ idle &+ nice }
}

/// A single raw sample across all cores.
public struct CPUSample: Equatable {
    public let cores: [CoreTicks]

    public init(cores: [CoreTicks]) {
        self.cores = cores
    }
}

/// Usage of a single core (for the top-N list).
public struct CoreUsage: Equatable {
    public let index: Int
    public let usage: Double

    public init(index: Int, usage: Double) {
        self.index = index
        self.usage = usage
    }
}

/// Ready-to-display snapshot for the UI.
public struct CPUSnapshot: Equatable {
    public var totalUsage: Double      // 0...1
    public var topCores: [CoreUsage]
    public var loadAverage: [Double]   // 1 / 5 / 15 minutes
    public var coreCount: Int

    public init(totalUsage: Double, topCores: [CoreUsage], loadAverage: [Double], coreCount: Int) {
        self.totalUsage = totalUsage
        self.topCores = topCores
        self.loadAverage = loadAverage
        self.coreCount = coreCount
    }
}
