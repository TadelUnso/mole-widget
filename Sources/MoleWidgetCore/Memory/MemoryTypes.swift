/// Raw page counters from vm_statistics64.
/// The inactive/speculative fields are not used in the current formulas — we capture
/// the full set so formulas can be updated without modifying the collector.
public struct VMStats: Equatable {
    public let free: UInt64
    public let active: UInt64
    public let inactive: UInt64
    public let wired: UInt64
    public let compressed: UInt64
    public let purgeable: UInt64
    public let external: UInt64
    public let speculative: UInt64

    public init(free: UInt64, active: UInt64, inactive: UInt64, wired: UInt64,
                compressed: UInt64, purgeable: UInt64, external: UInt64, speculative: UInt64) {
        self.free = free
        self.active = active
        self.inactive = inactive
        self.wired = wired
        self.compressed = compressed
        self.purgeable = purgeable
        self.external = external
        self.speculative = speculative
    }
}

/// Ready-to-display memory snapshot for the UI (all values in bytes).
public struct MemorySnapshot: Equatable {
    public let total: UInt64
    public let used: UInt64
    public let free: UInt64
    public let cached: UInt64
    public let available: UInt64

    public init(total: UInt64, used: UInt64, free: UInt64, cached: UInt64, available: UInt64) {
        self.total = total
        self.used = used
        self.free = free
        self.cached = cached
        self.available = available
    }

    public var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
    public var freeFraction: Double { total > 0 ? Double(free) / Double(total) : 0 }
}
