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

    @Test func roundTripsThroughCodable() throws {
        let entry = try Entry(draft: draft(note: "Walk note"))
        let decoded = try JSONDecoder().decode(Entry.self, from: JSONEncoder().encode(entry))
        #expect(decoded == entry)
    }

    @Test func encodesTheFiveKeysWithTheKindAsItsRawValue() throws {
        let entry = try Entry(draft: draft(note: "Walk note"))
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object.map { Set($0.keys) } == Set(["id", "kind", "severity", "date", "note"]))
        #expect(object?["kind"] as? String == "stiffness")
        #expect(object?["severity"] as? Int == 4)
    }

    @Test func omitsTheNoteKeyWhenThereIsNoNote() throws {
        let entry = try Entry(draft: draft())
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(entry)) as? [String: Any]
        #expect(object?["note"] == nil)
    }
}
