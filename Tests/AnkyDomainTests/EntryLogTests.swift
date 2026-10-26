import AnkyDomain
import Foundation
import Testing

struct EntryLogTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(id: UUID = UUID(), severity: Int = 4) throws -> Entry {
        try Entry(id: id, draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    @Test func loadsTheStoredEntriesInSaveOrder() throws {
        let first = try entry()
        let second = try entry()
        let log = EntryLog(store: FakeEntryStore(entries: [first, second]))
        #expect(log.entries == [first, second])
    }

    @Test func startsEmptyWhenTheStoreCannotBeRead() throws {
        let log = try EntryLog(store: FakeEntryStore(entries: [entry()], loadError: .unreadable))
        #expect(log.entries.isEmpty)
    }

    @Test func addSavesTheWholeListWithTheEntryAppended() throws {
        let first = try entry()
        let second = try entry()
        let store = FakeEntryStore(entries: [first])
        var log = EntryLog(store: store)

        try log.add(second)

        #expect(log.entries == [first, second])
        #expect(store.saveCalls == [[first, second]])
    }

    @Test func failedSaveLeavesTheListAsItWasAndThrowsTheStoreError() throws {
        let earlier = try entry()
        let store = FakeEntryStore(entries: [earlier])
        store.saveFailure = SaveFailure()
        var log = EntryLog(store: store)

        #expect(throws: SaveFailure()) { try log.add(entry()) }

        #expect(log.entries == [earlier])
        #expect(store.saved == [earlier])
    }

    @Test func retryingAfterAFailedSaveAddsTheSameEntry() throws {
        let store = FakeEntryStore()
        var log = EntryLog(store: store)
        let tapped = try entry()
        store.saveFailure = SaveFailure()
        #expect(throws: SaveFailure()) { try log.add(tapped) }

        store.saveFailure = nil
        try log.add(tapped)

        #expect(log.entries == [tapped])
        #expect(store.saveCalls.count == 2)
    }

    @Test func addingTheSameEntryTwiceKeepsOneAndSavesOnce() throws {
        let store = FakeEntryStore()
        var log = EntryLog(store: store)
        let tapped = try entry()

        try log.add(tapped)
        try log.add(tapped)

        #expect(log.entries == [tapped])
        #expect(store.saveCalls.count == 1)
    }

    @Test func anotherEntryWithAKnownIDChangesNothing() throws {
        let id = UUID()
        let original = try entry(id: id, severity: 4)
        let impostor = try entry(id: id, severity: 9)
        let store = FakeEntryStore()
        var log = EntryLog(store: store)

        try log.add(original)
        try log.add(impostor)

        #expect(log.entries == [original])
        #expect(store.saveCalls.count == 1)
    }
}
