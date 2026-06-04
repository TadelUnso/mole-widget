/// Pure math: memory snapshot computed from raw page counters.
/// Formulas:
///   used   = active + wired + compressed   (matches Activity Monitor)
///   free   = total − used                  (complement of Used, as in `mo status`;
///                                           NOT the kernel free_count!)
///   cached = purgeable + external          (file-backed pages)
///   avail  = free_count + cached           (actually available without eviction)
public enum MemoryUsage {
    public static func compute(stats: VMStats, pageSize: UInt64, total: UInt64) -> MemorySnapshot {
        let used = (stats.active &+ stats.wired &+ stats.compressed) &* pageSize
        let cached = (stats.purgeable &+ stats.external) &* pageSize
        let free = total > used ? total - used : 0
        let available = stats.free &* pageSize &+ cached
        return MemorySnapshot(total: total, used: used, free: free, cached: cached, available: available)
    }
}
