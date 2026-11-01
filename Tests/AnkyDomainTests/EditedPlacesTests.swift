// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EditedPlacesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let lower = PlaceID(rawValue: "lower")
    private let siLeft = PlaceID(rawValue: "si_l")
    private let unknown = PlaceID(rawValue: "tentacle")

    private func entry(places: [PlaceID] = [], kind: EntryKind = .pain) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = kind
        draft.places = places
        return Entry(draft: draft)
    }

    @Test func editingAnEntryKeepsAnIdThisBuildDoesNotKnow() throws {
        let saved = try entry(places: [unknown])
        var draft = try EntryDraft(entry: saved)

        draft.togglePlace(lower)

        #expect(draft.places == [lower, unknown])
        #expect(Entry(id: saved.id, draft: draft).places == [lower, unknown])
    }

    @Test(arguments: StoreKind.allCases) func aReplacedEntryCarriesTheEditedPlaces(_ kind: StoreKind) throws {
        let fixture = try kind.fixture(holding: [])
        let first = try entry()
        let middle = try entry()
        let last = try entry()
        var log = EntryLog(store: fixture.store)
        try log.add(first)
        try log.add(middle)
        try log.add(last)
        var draft = try EntryDraft(entry: middle)
        draft.togglePlace(lower)
        draft.togglePlace(siLeft)

        try log.replace(Entry(id: middle.id, draft: draft))

        let reloaded = try EntryLog(store: fixture.reopen()).entries
        #expect(reloaded.map(\.id) == [first.id, middle.id, last.id])
        #expect(reloaded[1].places == [lower, siLeft])
    }

    @Test func anEntryEditedFromFatigueToPainStartsWithNoPlaces() throws {
        var fatigue = try EntryDraft(severity: #require(Severity(4)), date: date)
        fatigue.kind = .fatigue
        fatigue.togglePlace(lower)
        var draft = try EntryDraft(entry: Entry(draft: fatigue))

        draft.kind = .pain

        #expect(draft.places.isEmpty)
    }
}
