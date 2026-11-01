// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EntryLogTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(id: UUID = UUID(), severity: Int = 4) throws -> Entry {
        try Entry(id: id, draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    @Test(arguments: StoreKind.allCases) func loadsTheStoredEntriesInSaveOrder(_ kind: StoreKind) throws {
        let first = try entry()
        let second = try entry()
        let fixture = try kind.fixture(holding: [first, second])
        let log = EntryLog(store: fixture.store)
        #expect(log.entries == [first, second])
    }

    @Test(arguments: StoreKind.allCases) func startsEmptyWhenTheStoreCannotBeRead(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [entry()])
        fixture.refuseLoads(.unreadable)
        let log = EntryLog(store: fixture.store)
        #expect(log.entries.isEmpty)
    }

    @Test(arguments: StoreKind.allCases) func addSavesTheWholeListWithTheEntryAppended(_ kind: StoreKind) throws {
        let first = try entry()
        let second = try entry()
        let fixture = try kind.fixture(holding: [first])
        var log = EntryLog(store: fixture.store)

        try log.add(second)

        #expect(log.entries == [first, second])
        #expect(try fixture.store.load() == [first, second])
    }

    @Test(arguments: StoreKind.allCases) func failedSaveLeavesTheListAsItWasAndThrowsTheStoreError(
        _ kind: StoreKind
    ) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        fixture.refuseWrites(true)
        var log = EntryLog(store: fixture.store)

        #expect(throws: EntryStoreError.notSaved) { try log.add(entry()) }

        #expect(log.entries == [earlier])
        #expect(try fixture.store.load() == [earlier])
    }

    @Test(arguments: StoreKind.allCases) func retryingAfterAFailedSaveAddsTheSameEntry(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [])
        var log = EntryLog(store: fixture.store)
        let tapped = try entry()
        fixture.refuseWrites(true)
        #expect(throws: EntryStoreError.notSaved) { try log.add(tapped) }

        fixture.refuseWrites(false)
        try log.add(tapped)

        #expect(log.entries == [tapped])
        #expect(fixture.writeCount() == 2)
    }

    @Test(arguments: StoreKind.allCases) func addingTheSameEntryTwiceKeepsOneAndSavesOnce(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [])
        var log = EntryLog(store: fixture.store)
        let tapped = try entry()

        try log.add(tapped)
        try log.add(tapped)

        #expect(log.entries == [tapped])
        #expect(fixture.writeCount() == 1)
    }

    @Test(arguments: StoreKind.allCases) func anotherEntryWithAKnownIDChangesNothing(_ kind: StoreKind) throws {
        let id = UUID()
        let original = try entry(id: id, severity: 4)
        let impostor = try entry(id: id, severity: 9)
        let fixture = try kind.fixture(holding: [])
        var log = EntryLog(store: fixture.store)

        try log.add(original)
        try log.add(impostor)

        #expect(log.entries == [original])
        #expect(fixture.writeCount() == 1)
    }
}
