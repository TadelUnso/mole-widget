import Foundation

/// Builds the compact live-metrics string shown in the menu bar.
///
/// The menu bar has little room, so this uses a tighter format than `Fmt`
/// (integer percent, one-decimal gigabytes, integer degrees). Enabled metrics
/// whose data is not yet available render as `--` placeholders; when no metric
/// is enabled the function returns `nil` so the caller falls back to the icon.
public enum MenuBarText {
    /// - Parameters:
    ///   - cpuFraction: `MetricsStore.cpu?.totalUsage`, range 0...1.
    ///   - memFraction: `MetricsStore.memory?.usedFraction`, range 0...1.
    ///   - batteryTempC: `MetricsStore.power?.temperatureCelsius`.
    /// - Returns: e.g. `"CPU 42%  MEM 34%  TEMP 31°"`, or `nil` when nothing is enabled.
    public static func compose(
        cpuFraction: Double?,
        memFraction: Double?,
        batteryTempC: Double?,
        showCPU: Bool,
        showMemory: Bool,
        showTemp: Bool
    ) -> String? {
        guard showCPU || showMemory || showTemp else { return nil }

        var parts: [String] = []
        if showCPU {
            parts.append("CPU " + (cpuFraction.map(percent) ?? placeholder))
        }
        if showMemory {
            parts.append("MEM " + (memFraction.map(percent) ?? placeholder))
        }
        if showTemp {
            parts.append("TEMP " + (batteryTempC.map(degrees) ?? placeholder))
        }
        return parts.joined(separator: "  ")
    }

    private static let placeholder = "--"

    private static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    private static func degrees(_ celsius: Double) -> String {
        "\(Int(celsius.rounded()))°"
    }
}
