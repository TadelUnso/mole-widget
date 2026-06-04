/// Battery snapshot. Optional fields come from the AppleSmartBattery registry
/// and may be absent (e.g. a Mac mini has no battery at all → snapshot is nil).
public struct PowerSnapshot: Equatable {
    public let levelFraction: Double        // 0...1
    public let healthFraction: Double?      // 0...1
    public let isCharging: Bool
    public let timeRemainingMinutes: Int?   // time to discharge or to full charge
    public let cycleCount: Int?
    public let temperatureCelsius: Double?

    public init(levelFraction: Double, healthFraction: Double?, isCharging: Bool,
                timeRemainingMinutes: Int?, cycleCount: Int?, temperatureCelsius: Double?) {
        self.levelFraction = levelFraction
        self.healthFraction = healthFraction
        self.isCharging = isCharging
        self.timeRemainingMinutes = timeRemainingMinutes
        self.cycleCount = cycleCount
        self.temperatureCelsius = temperatureCelsius
    }
}
