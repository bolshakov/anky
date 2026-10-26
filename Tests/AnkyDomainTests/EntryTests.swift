import AnkyDomain
import Foundation
import Testing

struct EntryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft(note: String = "") throws -> EntryDraft {
        var draft = EntryDraft(severity: try #require(Severity(4)), date: date)
        draft.kind = .stiffness
        draft.note = note
        return draft
    }

    @Test func keepsTheDraftsFieldsAndTheGivenID() throws {
        let id = UUID()
        let entry = Entry(id: id, draft: try draft(note: "Walk note"))
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
        #expect(Entry(draft: try draft()).note == nil)
    }

    @Test func roundTripsThroughCodable() throws {
        let entry = Entry(draft: try draft(note: "Walk note"))
        let decoded = try JSONDecoder().decode(Entry.self, from: JSONEncoder().encode(entry))
        #expect(decoded == entry)
    }

    @Test func encodesTheFiveKeysWithTheKindAsItsRawValue() throws {
        let entry = Entry(draft: try draft(note: "Walk note"))
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object.map { Set($0.keys) } == Set(["id", "kind", "severity", "date", "note"]))
        #expect(object?["kind"] as? String == "stiffness")
        #expect(object?["severity"] as? Int == 4)
    }

    @Test func omitsTheNoteKeyWhenThereIsNoNote() throws {
        let entry = Entry(draft: try draft())
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object?["note"] == nil)
    }
}
