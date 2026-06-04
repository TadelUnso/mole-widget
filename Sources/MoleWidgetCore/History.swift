/// Fixed-capacity ring buffer of recent samples (oldest first).
public struct History: Equatable {
    public private(set) var values: [Double] = []
    public let capacity: Int

    public init(capacity: Int = 30) {
        self.capacity = capacity
    }

    /// Appends a new sample. If the buffer exceeds capacity, the oldest values are dropped.
    public mutating func push(_ value: Double) {
        values.append(value)
        if values.count > capacity { values.removeFirst(values.count - capacity) }
    }
}
