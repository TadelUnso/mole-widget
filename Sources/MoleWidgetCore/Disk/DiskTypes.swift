/// Volume usage (in bytes).
public struct DiskUsageSnapshot: Equatable {
    public let total: UInt64
    public let free: UInt64
    public let fileSystem: String

    public init(total: UInt64, free: UInt64, fileSystem: String) {
        self.total = total
        self.free = free
        self.fileSystem = fileSystem
    }

    public var used: UInt64 { total > free ? total - free : 0 }
    public var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
}

/// Cumulative I/O counters since system boot.
public struct DiskIOCounters: Equatable {
    public let bytesRead: UInt64
    public let bytesWritten: UInt64

    public init(bytesRead: UInt64, bytesWritten: UInt64) {
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
    }
}

/// Current read/write rates (bytes/s).
public struct DiskIORates: Equatable {
    public let read: Double
    public let write: Double

    public init(read: Double, write: Double) {
        self.read = read
        self.write = write
    }
}
