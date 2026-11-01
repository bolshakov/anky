// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EditedEntryReloadTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(severity: Int = 4) throws -> Entry {
        try Entry(draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    @Test(arguments: StoreKind.allCases) func aChangedLevelSurvivesAReloadFromTheFile(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [])
        var log = EntryLog(store: fixture.store)
        let original = try entry(severity: 4)
        try log.add(original)

        try log.replace(Entry(id: original.id, draft: EntryDraft(severity: #require(Severity(6)), date: date)))

        let reloaded = try EntryLog(store: fixture.reopen())
        #expect(reloaded.entries.count == 1)
        #expect(reloaded.entries.first?.severity == Severity(6))
    }

    @Test(arguments: StoreKind.allCases) func aRemovedEntryStaysGoneAfterAReloadFromTheFile(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [])
        var log = EntryLog(store: fixture.store)
        let removed = try entry()
        try log.add(removed)
        try log.add(entry())

        try log.remove(id: removed.id)

        #expect(try EntryLog(store: fixture.reopen()).entries.count == 1)
    }
}
