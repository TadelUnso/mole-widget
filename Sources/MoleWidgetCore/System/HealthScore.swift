/// Composite system health score (0…100).
public enum HealthScore {
    /// Computes a 0…100 health score from current metric snapshots.
    ///
    /// Starts at 100 and applies the following penalties:
    /// - `cpu > 0.8` → −15
    /// - `memUsedFraction > 0.85` → −15
    /// - `diskUsedFraction > 0.9` → −20
    /// - `batteryHealth < 0.8` → −10
    /// - `batteryLevel < 0.15 && !isCharging` → −10
    ///
    /// `nil` inputs contribute no penalty. Result is clamped to 0…100.
    public static func compute(
        cpu: Double?,
        memUsedFraction: Double?,
        diskUsedFraction: Double?,
        batteryHealth: Double?,
        batteryLevel: Double?,
        isCharging: Bool
    ) -> Int {
        var score = 100

        if let cpu, cpu > 0.8 {
            score -= 15
        }
        if let mem = memUsedFraction, mem > 0.85 {
            score -= 15
        }
        if let disk = diskUsedFraction, disk > 0.9 {
            score -= 20
        }
        if let health = batteryHealth, health < 0.8 {
            score -= 10
        }
        if let level = batteryLevel, level < 0.15, !isCharging {
            score -= 10
        }

        return max(0, min(100, score))
    }
}
