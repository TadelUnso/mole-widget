/// Pure math: CPU usage computed from tick deltas between two samples.
/// If the core count differs between samples, extra cores are silently dropped (zip).
public enum CPUUsage {
    public static func perCore(previous: CPUSample, current: CPUSample) -> [Double] {
        zip(previous.cores, current.cores).map { prev, cur in
            let deltaTotal = cur.total &- prev.total
            guard deltaTotal > 0 else { return 0 }
            // min: guards against kernel anomalies (ticks can roll back in rare power-state cases)
            return min(1.0, Double(cur.busy &- prev.busy) / Double(deltaTotal))
        }
    }

    /// Aggregate weighted by ticks across all cores (rather than a per-core mean —
    /// more stable when deltas are uneven between samples).
    public static func total(previous: CPUSample, current: CPUSample) -> Double {
        var busy: UInt64 = 0
        var all: UInt64 = 0
        for (prev, cur) in zip(previous.cores, current.cores) {
            busy &+= cur.busy &- prev.busy
            all &+= cur.total &- prev.total
        }
        guard all > 0 else { return 0 }
        return min(1.0, Double(busy) / Double(all))
    }

    public static func topCores(_ usages: [Double], count: Int) -> [CoreUsage] {
        usages.enumerated()
            // on equal usage — stable order by core index (prevents UI flickering)
            .sorted { $0.element != $1.element ? $0.element > $1.element : $0.offset < $1.offset }
            .prefix(count)
            .map { CoreUsage(index: $0.offset, usage: $0.element) }
    }

    public static func snapshot(
        previous: CPUSample,
        current: CPUSample,
        loadAverage: [Double],
        topCount: Int = 3
    ) -> CPUSnapshot {
        let usages = perCore(previous: previous, current: current)
        return CPUSnapshot(
            totalUsage: total(previous: previous, current: current),
            topCores: topCores(usages, count: topCount),
            loadAverage: loadAverage,
            coreCount: usages.count
        )
    }
}
