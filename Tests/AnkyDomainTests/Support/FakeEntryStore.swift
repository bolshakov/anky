// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A store held in memory. Tests read `saveCalls` to see every save, failed ones included.
final class FakeEntryStore: EntryStore, @unchecked Sendable {
    // Every property is read and written under `lock`, so copies of a log can share one store.
    private let lock = NSLock()
    private var contents: [Entry]
    private var loadError: EntryStoreError?
    private var failure: SaveFailure?
    private var calls: [[Entry]] = []

    init(entries: [Entry] = [], loadError: EntryStoreError? = nil) {
        contents = entries
        self.loadError = loadError
    }

    var saveCalls: [[Entry]] {
        lock.withLock { calls }
    }

    var saved: [Entry] {
        lock.withLock { contents }
    }

    /// Set to make the next saves throw. Set back to nil to let them succeed.
    var saveFailure: SaveFailure? {
        get { lock.withLock { failure } }
        set { lock.withLock { failure = newValue } }
    }

    func load() throws -> [Entry] {
        try lock.withLock {
            if let loadError {
                throw loadError
            }
            return contents
        }
    }

    func save(_ entries: [Entry]) throws {
        try lock.withLock {
            calls.append(entries)
            if let failure {
                throw failure
            }
            contents = entries
        }
    }
}

struct SaveFailure: Error, Equatable {}
