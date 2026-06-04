/// Pure battery math.
public enum BatteryMath {
    /// Health = actual capacity / design capacity, clamped to 100%.
    public static func health(rawMaxCapacity: Int, designCapacity: Int) -> Double? {
        guard designCapacity > 0 else { return nil }
        return min(1.0, Double(rawMaxCapacity) / Double(designCapacity))
    }

    /// "Temperature" in the AppleSmartBattery registry — hundredths of °C (3020 → 30.2°C).
    public static func celsius(fromRawTemperature raw: Int) -> Double {
        Double(raw) / 100.0
    }

    /// 411 → "6:51"; negative values are treated as zero.
    public static func formatMinutes(_ minutes: Int) -> String {
        let m = max(0, minutes)
        return String(format: "%d:%02d", m / 60, m % 60)
    }
}
