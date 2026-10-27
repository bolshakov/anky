import AnkyDomain
import Foundation
import Testing

struct NoteCounterTests {
    private func draft(note: String) throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: Date(timeIntervalSince1970: 0))
        draft.note = note
        return draft
    }

    @Test func noteCounterIsNilWithNoNote() throws {
        #expect(try draft(note: "").noteCounter == nil)
    }

    @Test func noteCounterIsNilAtFortyCharactersLeft() throws {
        #expect(try draft(note: String(repeating: "a", count: 200)).noteCounter == nil)
    }

    @Test func noteCounterReadsThirtyNineLeftAtTwoHundredOneCharacters() throws {
        #expect(try draft(note: String(repeating: "a", count: 201)).noteCounter == .left(39))
    }

    @Test func noteCounterReadsTenLeftAtTwoHundredThirtyCharacters() throws {
        #expect(try draft(note: String(repeating: "a", count: 230)).noteCounter == .left(10))
    }

    @Test func noteCounterReadsOneLeftAtTwoHundredThirtyNineCharacters() throws {
        #expect(try draft(note: String(repeating: "a", count: 239)).noteCounter == .left(1))
    }

    @Test func noteCounterIsLimitReachedAtTwoHundredFortyCharacters() throws {
        #expect(try draft(note: String(repeating: "a", count: 240)).noteCounter == .limitReached)
    }

    @Test func noteCounterCountsAnAccentedLetterOnceNearTheLimit() throws {
        let note = String(repeating: "e\u{301}", count: 230)
        #expect(try draft(note: note).noteCounter == .left(10))
    }

    @Test func noteCounterCountsAnEmojiOnceAtTheLimit() throws {
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"
        #expect(try draft(note: String(repeating: family, count: 240)).noteCounter == .limitReached)
    }

    @Test func noteOfOnlySpacesIsAChangeToTheDraftItOpenedFrom() throws {
        let opening = try draft(note: "")
        #expect(try draft(note: "   ") != opening)
    }
}
