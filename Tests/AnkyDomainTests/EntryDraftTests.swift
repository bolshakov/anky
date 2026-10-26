import AnkyDomain
import Foundation
import Testing

struct EntryDraftTests {
    @Test func startsAsPainWithNoNote() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = EntryDraft(severity: try #require(Severity(4)), date: date)
        #expect(draft.kind == .pain)
        #expect(draft.severity == Severity(4))
        #expect(draft.date == date)
        #expect(draft.note == "")
    }
}
