import Darwin

/// Collects raw CPU ticks via the mach API.
public struct CPUCollector {
    public init() {}

    /// Tick snapshot across all cores. nil if the mach call fails.
    public func sampleTicks() -> CPUSample? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        var cores: [CoreTicks] = []
        cores.reserveCapacity(Int(cpuCount))
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * Int(CPU_STATE_MAX)
            // Ticks are unsigned 32-bit counters stored as Int32 in the C array.
            func tick(_ state: Int32) -> UInt64 {
                UInt64(UInt32(bitPattern: info[base + Int(state)]))
            }
            cores.append(CoreTicks(
                user: tick(CPU_STATE_USER),
                system: tick(CPU_STATE_SYSTEM),
                idle: tick(CPU_STATE_IDLE),
                nice: tick(CPU_STATE_NICE)
            ))
        }
        return CPUSample(cores: cores)
    }

    /// Load average over 1 / 5 / 15 minutes.
    public func loadAverage() -> [Double] {
        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        return loads
    }
}
