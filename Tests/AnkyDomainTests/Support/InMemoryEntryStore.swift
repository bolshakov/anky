// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// Counts only the writes that got past the store's own no-op checks, refused ones included.
@MainActor
final class InMemoryEntryStore: EntryStore {
    private var entries: [Entry]
    private(set) var writeCount = 0
    var refusesWrites = false
    var loadError: EntryStoreError?

    init(entries: [Entry] = []) {
        self.entries = entries
    }

    func load() throws -> [Entry] {
        if let loadError {
            throw loadError
        }
        return entries
    }

    func add(_ entry: Entry) throws {
        guard !entries.contains(where: { $0.id == entry.id }) else { return }
        try write { entries.append(entry) }
    }

    func replace(_ entry: Entry) throws {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            throw EntryStoreError.notSaved
        }
        try write { entries[index] = entry }
    }

    func remove(id: UUID) throws {
        guard entries.contains(where: { $0.id == id }) else { return }
        try write { entries.removeAll { $0.id == id } }
    }

    private func write(_ change: () -> Void) throws {
        writeCount += 1
        if refusesWrites {
            throw EntryStoreError.notSaved
        }
        change()
    }
}
