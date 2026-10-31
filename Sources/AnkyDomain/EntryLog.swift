// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct EntryLog: Sendable {
    private let store: any EntryStore
    public private(set) var entries: [Entry]

    public init(store: any EntryStore) {
        self.store = store
        entries = (try? store.load()) ?? []
    }

    public mutating func add(_ entry: Entry) throws {
        guard !entries.contains(where: { $0.id == entry.id }) else { return }
        let saved = entries + [entry]
        // The list changes only after the store accepts it, so a failed save leaves the log as it was.
        try store.save(saved)
        entries = saved
    }

    public mutating func replace(_ entry: Entry) throws {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            throw EntryLogError.missing
        }
        var saved = entries
        saved[index] = entry
        try store.save(saved)
        entries = saved
    }

    public mutating func remove(id: UUID) throws {
        guard entries.contains(where: { $0.id == id }) else { return }
        let saved = entries.filter { $0.id != id }
        try store.save(saved)
        entries = saved
    }
}
