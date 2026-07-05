import Foundation

/// Severity of a menu bar value, used to color it (matches the widget bars:
/// green/neutral below 60 %, yellow below 85 %, red above).
public enum MenuBarLevel: Equatable {
    case normal, warning, danger

    /// Same thresholds as `Theme.barColor(for:)`.
    public static func of(_ fraction: Double) -> MenuBarLevel {
        switch fraction {
        case ..<0.6: .normal
        case ..<0.85: .warning
        default: .danger
        }
    }
}

/// One menu bar metric: a short label and its formatted value, rendered as a
/// two-line column (label on top, value below) to save horizontal space.
public struct MenuBarMetric: Equatable {
    public let label: String
    public let value: String
    public let level: MenuBarLevel

    public init(label: String, value: String, level: MenuBarLevel) {
        self.label = label
        self.value = value
        self.level = level
    }
}

/// Builds the live menu bar metrics.
///
/// Uses a tight format (integer percent, integer degrees). An enabled metric
/// whose value is `nil` is omitted entirely — this keeps the menu bar clean at
/// startup and on Macs without a given sensor. An empty result means the caller
/// should fall back to the icon.
public enum MenuBarText {
    /// - Parameters:
    ///   - cpuFraction: `MetricsStore.cpu?.totalUsage`, range 0...1.
    ///   - memFraction: `MetricsStore.memory?.usedFraction`, range 0...1.
    ///   - temperatureC: `MetricsStore.cpuTemperature` (SoC die temperature).
    /// - Returns: e.g. `[CPU/42%, MEM/34%, TEMP/54°]`, empty when nothing to show.
    public static func metrics(
        cpuFraction: Double?,
        memFraction: Double?,
        temperatureC: Double?,
        showCPU: Bool,
        showMemory: Bool,
        showTemp: Bool
    ) -> [MenuBarMetric] {
        var result: [MenuBarMetric] = []
        if showCPU, let cpuFraction {
            result.append(MenuBarMetric(label: "CPU", value: percent(cpuFraction), level: .of(cpuFraction)))
        }
        if showMemory, let memFraction {
            result.append(MenuBarMetric(label: "MEM", value: percent(memFraction), level: .of(memFraction)))
        }
        if showTemp, let temperatureC {
            result.append(MenuBarMetric(label: "TEMP", value: degrees(temperatureC), level: .of(temperatureC / 100)))
        }
        return result
    }

    private static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    private static func degrees(_ celsius: Double) -> String {
        "\(Int(celsius.rounded()))°"
    }
}
