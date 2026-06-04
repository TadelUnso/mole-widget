import Foundation

/// Static hardware and OS information shown in the widget header.
public struct SystemInfoSnapshot: Equatable {
    /// CPU/chip model string (e.g. "Apple M3 Pro").
    public let chip: String
    /// Physical RAM size in bytes.
    public let ramBytes: UInt64
    /// macOS version string (e.g. "15.4" or "15.4.1").
    public let osVersion: String
    /// Seconds since last boot (from ProcessInfo.systemUptime).
    public let uptime: TimeInterval

    public init(chip: String, ramBytes: UInt64, osVersion: String, uptime: TimeInterval) {
        self.chip = chip
        self.ramBytes = ramBytes
        self.osVersion = osVersion
        self.uptime = uptime
    }

    /// Formats a raw uptime duration into a human-readable string.
    ///
    /// - `< 1h`  → "up 36m"
    /// - `< 24h` → "up 5h 36m"
    /// - `≥ 24h` → "up 3d 4h"
    public static func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = (total % 3600) / 60
        let hours = (total % 86400) / 3600
        let days = total / 86400

        if total < 3600 {
            return "up \(total / 60)m"
        } else if total < 86400 {
            return "up \(hours)h \(minutes)m"
        } else {
            return "up \(days)d \(hours)h"
        }
    }
}

/// Collects static system information via sysctl and ProcessInfo.
public final class SystemInfoCollector {
    public init() {}

    /// Samples static hardware/OS information.
    /// Returns `nil` only if the sysctl calls fail completely.
    public func sample() -> SystemInfoSnapshot? {
        guard let chip = cpuBrandString(), let ram = memorySize() else {
            return nil
        }
        let os = osVersionString()
        let uptime = ProcessInfo.processInfo.systemUptime
        return SystemInfoSnapshot(chip: chip, ramBytes: ram, osVersion: os, uptime: uptime)
    }

    // MARK: - Private helpers

    /// Reads `machdep.cpu.brand_string` via a two-phase sysctl call.
    private func cpuBrandString() -> String? {
        var size = 0
        guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 else {
            return appleChipName()
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else {
            return appleChipName()
        }
        let name = String(cString: buffer)
        return name.isEmpty ? appleChipName() : name
    }

    /// Fallback for Apple Silicon where `machdep.cpu.brand_string` may be absent.
    /// Reads `machdep.cpu.brand_string` is unavailable; uses `hw.model` instead.
    private func appleChipName() -> String? {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else {
            return nil
        }
        let model = String(cString: buffer)
        return model.isEmpty ? nil : model
    }

    /// Reads physical memory size via `hw.memsize`.
    private func memorySize() -> UInt64? {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        guard sysctlbyname("hw.memsize", &value, &size, nil, 0) == 0 else {
            return nil
        }
        return value
    }

    /// Formats the running OS version from ProcessInfo.
    private func osVersionString() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        if v.patchVersion > 0 {
            return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        }
        return "\(v.majorVersion).\(v.minorVersion)"
    }
}
