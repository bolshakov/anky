// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct DeferredEntryStoreTests {
    private struct Locked: Error {}

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ note: String = "") throws -> Entry {
        try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: note,
            places: []
        )
    }

    @Test func aStoreThatCannotOpenThrowsUnavailableAndOpensOnALaterCall() throws {
        let inner = try InMemoryEntryStore(entries: [entry("Zorblex")])
        var locked = true
        let store = DeferredEntryStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: EntryStoreError.unavailable) { try store.load() }
        #expect(throws: EntryStoreError.unavailable) { try store.add(entry()) }
        #expect(inner.writeCount == 0)
        locked = false
        #expect(try store.load().map(\.note) == ["Zorblex"])
    }

    @Test func anOpenedStoreIsNotOpenedAgain() throws {
        var attempts = 0
        let store = DeferredEntryStore {
            attempts += 1
            return InMemoryEntryStore()
        }
        let first = try entry()
        _ = try store.load()
        try store.add(first)
        try store.replace(first)
        try store.remove(id: first.id)
        #expect(attempts == 1)
    }

    @Test func aRefusalFromTheOpenedStoreKeepsItsOwnError() throws {
        let inner = InMemoryEntryStore()
        inner.refusesWrites = true
        let store = DeferredEntryStore { inner }
        #expect(throws: EntryStoreError.notSaved) { try store.add(entry()) }
    }

    @Test func entryLogStartsEmptyWhileLockedAndTakesWritesOnceTheStoreOpens() throws {
        var locked = true
        let inner = InMemoryEntryStore()
        let deferred = DeferredEntryStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        var log = EntryLog(store: deferred)
        #expect(log.entries.isEmpty)
        let refused = try entry("Stairs")
        #expect(throws: EntryStoreError.unavailable) { try log.add(refused) }
        #expect(log.entries.isEmpty)
        locked = false
        let kept = try entry("Walk note")
        try log.add(kept)
        #expect(log.entries.map(\.id) == [kept.id])
        #expect(inner.writeCount == 1)
    }
}
