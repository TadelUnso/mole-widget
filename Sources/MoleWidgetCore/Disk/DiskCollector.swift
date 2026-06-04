import Foundation
import IOKit

/// Root volume usage + cumulative I/O counters from IOKit.
public struct DiskCollector {
    public init() {}

    public func usage(path: String = "/") -> DiskUsageSnapshot? {
        let url = URL(fileURLWithPath: path)
        guard
            let values = try? url.resourceValues(forKeys: [
                .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
            ]),
            let total = values.volumeTotalCapacity,
            let available = values.volumeAvailableCapacityForImportantUsage
        else { return nil }

        var fs = statfs()
        let fsName: String
        if statfs(path, &fs) == 0 {
            fsName = withUnsafeBytes(of: fs.f_fstypename) { raw in
                String(cString: raw.bindMemory(to: CChar.self).baseAddress!)
            }.uppercased()
        } else {
            fsName = "?"
        }
        // max(0, …): APFS can return a negative available capacity under purgeable pressure,
        // and UInt64(negative) is a runtime trap.
        return DiskUsageSnapshot(
            total: UInt64(max(0, total)),
            free: UInt64(max(0, available)),
            fileSystem: fsName
        )
    }

    /// Sum of counters across all IOBlockStorageDriver entries (internal SSD + external drives).
    public func ioCounters() -> DiskIOCounters? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOBlockStorageDriver"),
            &iterator
        ) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var read: UInt64 = 0
        var written: UInt64 = 0
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            var unmanaged: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let props = unmanaged?.takeRetainedValue() as? [String: Any],
               let stats = props["Statistics"] as? [String: Any] {
                read &+= stats["Bytes (Read)"] as? UInt64 ?? 0
                written &+= stats["Bytes (Write)"] as? UInt64 ?? 0
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        return DiskIOCounters(bytesRead: read, bytesWritten: written)
    }
}
