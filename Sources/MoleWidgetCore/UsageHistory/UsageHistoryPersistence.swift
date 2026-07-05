import Foundation

/// JSON Lines persistence for usage history: one `UsageSample` per line at
/// `<directory>/usage-history.jsonl`. Appends are O(1); compaction rewrites the
/// whole file from a pruned in-memory array. Undecodable lines are skipped on
/// load so a partial write or schema drift never loses the rest of the history.
public struct UsageHistoryPersistence {
    private let fileURL: URL

    /// - Parameter directory: where `usage-history.jsonl` lives. Defaults to
    ///   `~/Library/Application Support/Mole Widget`, created on demand.
    public init(directory: URL? = nil) {
        let dir = directory ?? Self.defaultDirectory
        self.fileURL = dir.appendingPathComponent("usage-history.jsonl")
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Mole Widget", isDirectory: true)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    /// Appends a single sample as one JSON line. Creates the directory and file
    /// if needed. Silently no-ops on I/O failure — history is best-effort.
    public func append(_ sample: UsageSample) {
        guard let data = try? Self.encoder.encode(sample) else { return }
        var line = data
        line.append(0x0A) // '\n'

        ensureDirectoryExists()
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: line)
        } else {
            try? line.write(to: fileURL, options: .atomic)
        }
    }

    /// Loads all samples, skipping any line that fails to decode.
    public func loadAll() -> [UsageSample] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        return content.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? Self.decoder.decode(UsageSample.self, from: data)
        }
    }

    /// Rewrites the file from `samples` (used for hourly compaction after
    /// pruning). Atomic so a crash mid-write cannot truncate the history.
    public func rewrite(_ samples: [UsageSample]) {
        ensureDirectoryExists()
        var buffer = Data()
        for sample in samples {
            guard let data = try? Self.encoder.encode(sample) else { continue }
            buffer.append(data)
            buffer.append(0x0A)
        }
        try? buffer.write(to: fileURL, options: .atomic)
    }

    private func ensureDirectoryExists() {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
