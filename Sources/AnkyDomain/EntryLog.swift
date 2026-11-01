// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor
public struct EntryLog {
    private let store: any EntryStore
    public private(set) var entries: [Entry]

    public init(store: any EntryStore) {
        self.store = store
        entries = (try? store.load()) ?? []
    }

    public mutating func add(_ entry: Entry) throws {
        guard !entries.contains(where: { $0.id == entry.id }) else { return }
        // The list changes only after the store accepts the write, so a refused write leaves the log as it was.
        try store.add(entry)
        entries.append(entry)
    }

    public mutating func replace(_ entry: Entry) throws {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            throw EntryLogError.missing
        }
        try store.replace(entry)
        entries[index] = entry
    }

    public mutating func remove(id: UUID) throws {
        guard entries.contains(where: { $0.id == id }) else { return }
        try store.remove(id: id)
        entries.removeAll { $0.id == id }
    }
}
