import Foundation

/// Pure math: rates computed from cumulative counter deltas.
public enum DiskIO {
    public static func rates(
        previous: DiskIOCounters,
        current: DiskIOCounters,
        interval: TimeInterval
    ) -> DiskIORates {
        guard interval > 0 else { return DiskIORates(read: 0, write: 0) }
        // Counter reset (volume remount, reboot) causes current < previous —
        // treat such a delta as zero, otherwise the unsigned subtraction yields ~18 EB/s.
        let deltaRead = current.bytesRead >= previous.bytesRead
            ? current.bytesRead - previous.bytesRead : 0
        let deltaWrite = current.bytesWritten >= previous.bytesWritten
            ? current.bytesWritten - previous.bytesWritten : 0
        return DiskIORates(
            read: Double(deltaRead) / interval,
            write: Double(deltaWrite) / interval
        )
    }
}
