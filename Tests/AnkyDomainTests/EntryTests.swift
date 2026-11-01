// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft(note: String = "") throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = .stiffness
        draft.note = note
        return draft
    }

    @Test func keepsTheDraftsFieldsAndTheGivenID() throws {
        let id = UUID()
        let entry = try Entry(id: id, draft: draft(note: "Walk note"))
        #expect(entry.id == id)
        #expect(entry.kind == .stiffness)
        #expect(entry.severity == Severity(4))
        #expect(entry.date == date)
        #expect(entry.note == "Walk note")
    }

    @Test func givesEachNewEntryItsOwnID() throws {
        let draft = try draft()
        #expect(Entry(draft: draft).id != Entry(draft: draft).id)
    }

    @Test func leavesTheNoteOutWhenTheDraftHasNone() throws {
        #expect(try Entry(draft: draft()).note == nil)
    }

    @Test(arguments: [" ", "\n", "  \n \n  ", "\r\n", "\t"])
    func leavesTheNoteOutWhenItIsOnlySpacesAndNewLines(note: String) throws {
        #expect(try Entry(draft: draft(note: note)).note == nil)
    }

    @Test func keepsAMultiParagraphNoteExactlyAsTyped() throws {
        let note = "  Walk note\n\nSecond line\n  third  "
        #expect(try Entry(draft: draft(note: note)).note == note)
    }

    @Test func keepsTheSameCharactersAsTheDraft() throws {
        let typed = String(repeating: "a", count: 240) + "b"
        #expect(try Entry(draft: draft(note: typed)).note == String(repeating: "a", count: 240))
    }

    @Test func loadsAnOlderNoteLongerThanTheLimitWhole() throws {
        let longNote = String(repeating: "a", count: 1500)
        let entry = try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: longNote,
            places: []
        )
        #expect(entry.note == longNote)
    }

    @Test func roundTripsThroughCodable() throws {
        let entry = try Entry(draft: draft(note: "Walk note"))
        let decoded = try JSONDecoder().decode(Entry.self, from: JSONEncoder().encode(entry))
        #expect(decoded == entry)
    }

    @Test func encodesTheSixKeysWithTheKindAsItsRawValue() throws {
        let entry = try Entry(draft: draft(note: "Walk note"))
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object.map { Set($0.keys) } == Set(["id", "kind", "severity", "date", "note", "places"]))
        #expect(object?["kind"] as? String == "stiffness")
        #expect(object?["severity"] as? Int == 4)
    }

    @Test func omitsTheNoteKeyWhenThereIsNoNote() throws {
        let entry = try Entry(draft: draft())
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object?["note"] == nil)
    }

    @Test func storedFieldsInitKeepsEveryFieldAndTheGivenID() throws {
        let id = UUID()
        let entry = try Entry(
            id: id,
            kind: .pain,
            severity: #require(Severity(7)),
            date: date,
            note: "Walk note",
            places: []
        )
        #expect(entry.id == id)
        #expect(entry.kind == .pain)
        #expect(entry.severity == Severity(7))
        #expect(entry.date == date)
        #expect(entry.note == "Walk note")
    }

    @Test func storedFieldsInitKeepsANoteAsGiven() throws {
        let longNote = String(repeating: "a", count: 1500)
        let entry = try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: longNote,
            places: []
        )
        #expect(entry.note == longNote)
        let blank = try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: "  ",
            places: []
        )
        #expect(blank.note == "  ")
    }

    @Test func storedFieldsInitDropsPlacesForFatigue() throws {
        let jaw = PlaceID(rawValue: "jaw")
        let entry = try Entry(
            id: UUID(),
            kind: .fatigue,
            severity: #require(Severity(4)),
            date: date,
            note: nil,
            places: [jaw]
        )
        #expect(entry.places.isEmpty)
    }

    @Test func storedFieldsInitPutsKnownPlacesInCatalogOrderAndKeepsUnknownOnesLast() throws {
        let jaw = PlaceID(rawValue: "jaw")
        let lower = PlaceID(rawValue: "lower")
        let later = PlaceID(rawValue: "tentacle")
        let entry = try Entry(
            id: UUID(), kind: .stiffness, severity: #require(Severity(4)), date: date, note: nil,
            places: [later, jaw, lower]
        )
        #expect(entry.places == [lower, jaw, later])
    }
}
