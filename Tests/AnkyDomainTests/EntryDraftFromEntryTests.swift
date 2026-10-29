import AnkyDomain
import Foundation
import Testing

struct EntryDraftFromEntryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(kind: EntryKind, severity: Int, note: String) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(severity)), date: date)
        draft.kind = kind
        draft.note = note
        return Entry(draft: draft)
    }

    @Test func draftFromAnEntryHoldsKindTimeLevelAndNote() throws {
        let draft = try EntryDraft(entry: entry(kind: .stiffness, severity: 7, note: "Walk note"))
        #expect(draft.kind == .stiffness)
        #expect(draft.date == date)
        #expect(draft.severity == Severity(7))
        #expect(draft.note == "Walk note")
    }

    @Test func draftFromAnEntryWithNoNoteHasAnEmptyNote() throws {
        let draft = try EntryDraft(entry: entry(kind: .pain, severity: 4, note: ""))
        #expect(draft.note == "")
    }

    @Test func draftFromAnEntryCutsANoteOverTheLimit() throws {
        let note = String(repeating: "a", count: EntryDraft.noteLimit + 1)
        let json = #"{"id":"\#(UUID())","kind":"pain","severity":4,"date":0,"note":"\#(note)"}"#
        let stored = try JSONDecoder().decode(Entry.self, from: Data(json.utf8))
        #expect(try EntryDraft(entry: stored).note == String(repeating: "a", count: EntryDraft.noteLimit))
    }

    @Test func draftFromAnEntryIsNotChangedUntilAFieldChanges() throws {
        let source = try entry(kind: .fatigue, severity: 4, note: "Walk note")
        var draft = try EntryDraft(entry: source)
        let untouched = try EntryDraft(entry: source)
        #expect(draft == untouched)

        draft.severity = try #require(Severity(5))
        #expect(draft != untouched)
    }
}
