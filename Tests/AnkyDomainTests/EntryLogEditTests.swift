// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EntryLogEditTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
    }

    private func entry(id: UUID = UUID(), severity: Int = 4, at date: Date? = nil) throws -> Entry {
        try Entry(id: id, draft: EntryDraft(severity: #require(Severity(severity)), date: date ?? self.date))
    }

    private func moment(day: Int, hour: Int, minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)))
    }

    @Test(arguments: StoreKind.allCases) func replaceSwapsTheEntryWithTheSameIdAndKeepsItsPlace(
        _ kind: StoreKind
    ) throws {
        let first = try entry()
        let middle = try entry(severity: 4)
        let last = try entry()
        var log = try EntryLog(store: kind.fixture(holding: [first, middle, last]).store)
        let changed = try entry(id: middle.id, severity: 8)

        try log.replace(changed)

        #expect(log.entries == [first, changed, last])
    }

    @Test(arguments: StoreKind.allCases) func replaceSavesTheWholeListOnce(_ kind: StoreKind) throws {
        let first = try entry()
        let middle = try entry()
        let fixture = try kind.fixture(holding: [first, middle])
        var log = EntryLog(store: fixture.store)
        let changed = try entry(id: middle.id, severity: 8)

        try log.replace(changed)

        #expect(try fixture.store.load() == [first, changed])
        #expect(fixture.writeCount() == 1)
    }

    @Test(arguments: StoreKind.allCases) func replaceThrowsMissingWhenNoEntryHasThatId(_ kind: StoreKind) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        var log = EntryLog(store: fixture.store)

        #expect(throws: EntryLogError.missing) { try log.replace(entry()) }

        #expect(log.entries == [earlier])
        #expect(fixture.writeCount() == 0)
    }

    @Test(arguments: StoreKind.allCases) func failedReplaceLeavesTheListAsItWasAndThrowsTheStoreError(
        _ kind: StoreKind
    ) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        fixture.refuseWrites(true)
        var log = EntryLog(store: fixture.store)

        #expect(throws: EntryStoreError.notSaved) { try log.replace(entry(id: earlier.id, severity: 9)) }

        #expect(log.entries == [earlier])
    }

    @Test(arguments: StoreKind.allCases) func removeDropsTheEntryAndSavesTheList(_ kind: StoreKind) throws {
        let first = try entry()
        let second = try entry()
        let fixture = try kind.fixture(holding: [first, second])
        var log = EntryLog(store: fixture.store)

        try log.remove(id: first.id)

        #expect(log.entries == [second])
        #expect(try fixture.store.load() == [second])
        #expect(fixture.writeCount() == 1)
    }

    @Test(arguments: StoreKind.allCases) func removeOfAnUnknownIdSavesNothing(_ kind: StoreKind) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        var log = EntryLog(store: fixture.store)

        try log.remove(id: UUID())

        #expect(log.entries == [earlier])
        #expect(fixture.writeCount() == 0)
    }

    @Test(arguments: StoreKind.allCases) func failedRemoveLeavesTheListAsItWasAndThrowsTheStoreError(
        _ kind: StoreKind
    ) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        fixture.refuseWrites(true)
        var log = EntryLog(store: fixture.store)

        #expect(throws: EntryStoreError.notSaved) { try log.remove(id: earlier.id) }

        #expect(log.entries == [earlier])
    }

    @Test(arguments: StoreKind.allCases) func anEntryMovedToYesterdayLeavesTodayAndStaysStored(
        _ kind: StoreKind
    ) throws {
        let original = try entry(at: moment(day: 26, hour: 9))
        let fixture = try kind.fixture(holding: [original])
        var log = EntryLog(store: fixture.store)
        let today = try moment(day: 26, hour: 12)
        #expect(try TodayList.entries(log.entries, on: today, calendar: calendar).map(\.id) == [original.id])

        try log.replace(entry(id: original.id, at: moment(day: 25, hour: 23, minute: 50)))

        #expect(try TodayList.entries(log.entries, on: today, calendar: calendar).isEmpty)
        #expect(log.entries.count == 1)
    }
}
