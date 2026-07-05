import Foundation

/// A process entry recorded inside a `UsageSample`. Mirrors the live
/// `ProcessUsage` type but is `Codable` and decoupled from it so the persisted
/// schema can evolve independently.
public struct UsageProcess: Codable, Equatable {
    public let pid: Int32
    public let name: String
    public let cpuFraction: Double
    public let memoryBytes: UInt64

    public init(pid: Int32, name: String, cpuFraction: Double, memoryBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.cpuFraction = cpuFraction
        self.memoryBytes = memoryBytes
    }
}

/// One point-in-time snapshot of overall resource usage plus the heaviest
/// processes at that moment. Persisted one-per-line as JSON.
public struct UsageSample: Codable, Equatable, Identifiable {
    public let timestamp: Date
    public let cpuFraction: Double      // 0...1 overall CPU usage
    public let memUsedBytes: UInt64
    public let memTotalBytes: UInt64
    public let topProcesses: [UsageProcess]

    public var id: Date { timestamp }

    public init(
        timestamp: Date,
        cpuFraction: Double,
        memUsedBytes: UInt64,
        memTotalBytes: UInt64,
        topProcesses: [UsageProcess]
    ) {
        self.timestamp = timestamp
        self.cpuFraction = cpuFraction
        self.memUsedBytes = memUsedBytes
        self.memTotalBytes = memTotalBytes
        self.topProcesses = topProcesses
    }

    /// Overall memory usage as a 0...1 fraction (0 when total is unknown).
    public var memFraction: Double {
        memTotalBytes > 0 ? Double(memUsedBytes) / Double(memTotalBytes) : 0
    }
}
