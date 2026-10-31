// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntryDraftTests {
    private func draft(note: String) throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: Date(timeIntervalSince1970: 0))
        draft.note = note
        return draft
    }

    @Test func startsAsPainWithNoNote() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        #expect(draft.kind == .pain)
        #expect(draft.severity == Severity(4))
        #expect(draft.date == date)
        #expect(draft.note == "")
    }

    @Test func cutsANoteOneCharacterOverTheLimitBackToTheLimit() throws {
        let note = String(repeating: "a", count: 240) + "b"
        #expect(try draft(note: note).note == String(repeating: "a", count: 240))
    }

    @Test func keepsANoteOfExactlyTheLimitWhole() throws {
        let note = String(repeating: "a", count: 239) + "z"
        #expect(try draft(note: note).note == note)
    }

    @Test func keepsAShortNoteAsTyped() throws {
        let note = "Walk note\n\nSecond line"
        #expect(try draft(note: note).note == note)
    }

    @Test(arguments: ["\u{E9}", "e\u{301}", "\u{1F44D}\u{1F3FD}", "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"])
    func countsEachCharacterOnceSoNoneIsCutInHalf(character: String) throws {
        let note = String(repeating: character, count: 241)
        #expect(try draft(note: note).note == String(repeating: character, count: 240))
    }

    @Test func keepsAWholeCharacterThatEndsOnTheLimit() throws {
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"
        let note = String(repeating: "a", count: 239) + family + "b"
        #expect(try draft(note: note).note == String(repeating: "a", count: 239) + family)
    }
}
