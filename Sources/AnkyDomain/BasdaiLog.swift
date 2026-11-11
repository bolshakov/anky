// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The saved results, newest first by `date`, then by `createdAt`. The list changes only after the store accepts the
/// write, so a refused write leaves it as it was.
@MainActor public struct BasdaiLog {
    private let store: any BasdaiStore
    public private(set) var results: [BasdaiResult]

    public init(store: any BasdaiStore) {
        self.store = store
        results = ((try? store.all()) ?? []).sorted(by: Self.isNewer)
    }

    public mutating func add(_ r: BasdaiResult) throws {
        guard !results.contains(where: { $0.id == r.id }) else { return }
        try store.add(r)
        let index = results.firstIndex { Self.isNewer(r, than: $0) } ?? results.endIndex
        results.insert(r, at: index)
    }

    public mutating func remove(id: UUID) throws {
        guard results.contains(where: { $0.id == id }) else { return }
        try store.remove(id: id)
        results.removeAll { $0.id == id }
    }

    public mutating func removeAll() throws {
        try store.removeAll()
        results.removeAll()
    }

    private static func isNewer(_ lhs: BasdaiResult, than rhs: BasdaiResult) -> Bool {
        (lhs.date, lhs.createdAt) > (rhs.date, rhs.createdAt)
    }
}
