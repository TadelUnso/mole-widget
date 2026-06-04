import Foundation
import Testing
@testable import MoleWidgetCore

/// Tests for the History ring buffer.
@Suite struct HistoryTests {
    // MARK: - Push below capacity

    @Test func pushBelowCapacityKeepsAllValues() {
        var h = History(capacity: 30)
        for i in 0..<10 {
            h.push(Double(i))
        }
        #expect(h.values.count == 10)
        #expect(h.values.first == 0.0)
        #expect(h.values.last == 9.0)
    }

    // MARK: - Push exactly at capacity

    @Test func pushExactlyAtCapacityKeepsAll() {
        var h = History(capacity: 5)
        for i in 0..<5 {
            h.push(Double(i))
        }
        #expect(h.values.count == 5)
        #expect(h.values == [0.0, 1.0, 2.0, 3.0, 4.0])
    }

    // MARK: - Overflow drops oldest

    @Test func overflowDropsOldestValues() {
        var h = History(capacity: 30)
        // Push 35 values (0 through 34); the oldest 5 should be dropped.
        for i in 0..<35 {
            h.push(Double(i))
        }
        #expect(h.values.count == 30)
        // Oldest remaining value is 5 (indices 0-4 were dropped).
        #expect(h.values.first == 5.0)
        #expect(h.values.last == 34.0)
    }

    // MARK: - Order is oldest-first

    @Test func orderIsOldestFirst() {
        var h = History(capacity: 5)
        for i in 0..<7 {
            h.push(Double(i))
        }
        // Capacity 5, pushed 7: values 2,3,4,5,6.
        #expect(h.values == [2.0, 3.0, 4.0, 5.0, 6.0])
    }

    // MARK: - Capacity 1 edge case

    @Test func capacityOneKeepsOnlyLatest() {
        var h = History(capacity: 1)
        h.push(1.0)
        h.push(2.0)
        h.push(3.0)
        #expect(h.values.count == 1)
        #expect(h.values.first == 3.0)
    }

    // MARK: - Default capacity is 30

    @Test func defaultCapacityIsThirty() {
        let h = History()
        #expect(h.capacity == 30)
        #expect(h.values.isEmpty)
    }

    // MARK: - Equatable

    @Test func equatableEqual() {
        var a = History(capacity: 5)
        var b = History(capacity: 5)
        a.push(1.0)
        b.push(1.0)
        #expect(a == b)
    }

    @Test func equatableNotEqualValues() {
        var a = History(capacity: 5)
        var b = History(capacity: 5)
        a.push(1.0)
        b.push(2.0)
        #expect(a != b)
    }

    @Test func equatableNotEqualCapacity() {
        let a = History(capacity: 5)
        let b = History(capacity: 10)
        #expect(a != b)
    }
}
