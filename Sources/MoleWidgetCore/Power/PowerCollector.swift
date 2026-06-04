import Foundation
import IOKit
import IOKit.ps

/// Battery data collector: IOPowerSources (level, status) + AppleSmartBattery registry
/// (cycles, capacities, temperature).
public struct PowerCollector {
    public init() {}

    /// nil — if no battery power source is present (desktop Mac).
    public func sample() -> PowerSnapshot? {
        guard
            let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        // Look specifically for the internal battery: the first list entry may be an external UPS.
        let internalBattery = list.first { ref in
            let d = IOPSGetPowerSourceDescription(blob, ref)?.takeUnretainedValue() as? [String: Any]
            return d?[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
        }
        guard
            let source = internalBattery,
            let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any]
        else { return nil }

        let currentCapacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let timeKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        let minutes = desc[timeKey] as? Int ?? -1 // -1 = system is still estimating

        let battery = smartBatteryProperties()
        let cycleCount = battery?["CycleCount"] as? Int
        let designCapacity = battery?["DesignCapacity"] as? Int
        // On Apple Silicon "MaxCapacity" is a percentage; the actual capacity in mAh
        // is in AppleRawMaxCapacity (fallback: NominalChargeCapacity).
        let rawMax = (battery?["AppleRawMaxCapacity"] as? Int)
            ?? (battery?["NominalChargeCapacity"] as? Int)

        var health: Double?
        if let rawMax, let designCapacity {
            health = BatteryMath.health(rawMaxCapacity: rawMax, designCapacity: designCapacity)
        }
        let temperature = (battery?["Temperature"] as? Int)
            .map(BatteryMath.celsius(fromRawTemperature:))

        return PowerSnapshot(
            levelFraction: maxCapacity > 0 ? min(1.0, Double(currentCapacity) / Double(maxCapacity)) : 0,
            healthFraction: health,
            isCharging: isCharging,
            timeRemainingMinutes: minutes >= 0 ? minutes : nil,
            cycleCount: cycleCount,
            temperatureCelsius: temperature
        )
    }

    private func smartBatteryProperties() -> [String: Any]? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS
        else { return nil }
        return unmanaged?.takeRetainedValue() as? [String: Any]
    }
}
