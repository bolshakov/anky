// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EntryStoreContractTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(id: UUID = UUID(), severity: Int = 4) throws -> Entry {
        try Entry(id: id, draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    @Test(arguments: StoreKind.allCases) func addOfAKnownIdLeavesOneEntryAndWritesNothing(_ kind: StoreKind) throws {
        let id = UUID()
        let original = try entry(id: id, severity: 4)
        let impostor = try entry(id: id, severity: 9)
        let fixture = try kind.fixture(holding: [])
        try fixture.store.add(original)
        let writes = fixture.writeCount()

        try fixture.store.add(impostor)

        #expect(fixture.writeCount() == writes)
        #expect(try fixture.reopen().load() == [original])
    }

    @Test(arguments: StoreKind.allCases) func replaceKeepsThePlace(_ kind: StoreKind) throws {
        let first = try entry()
        let middle = try entry()
        let last = try entry()
        let fixture = try kind.fixture(holding: [first, middle, last])
        let changed = try entry(id: middle.id, severity: 8)

        try fixture.store.replace(changed)

        #expect(try fixture.reopen().load() == [first, changed, last])
    }

    @Test(arguments: StoreKind.allCases) func replaceOfAnUnknownIdThrowsNotSaved(_ kind: StoreKind) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])

        #expect(throws: EntryStoreError.notSaved) { try fixture.store.replace(entry()) }

        #expect(try fixture.reopen().load() == [earlier])
    }

    @Test(arguments: StoreKind.allCases) func removeOfAnUnknownIdWritesNothing(_ kind: StoreKind) throws {
        let earlier = try entry()
        let fixture = try kind.fixture(holding: [earlier])
        let writes = fixture.writeCount()

        try fixture.store.remove(id: UUID())

        #expect(fixture.writeCount() == writes)
        #expect(try fixture.reopen().load() == [earlier])
    }
}
