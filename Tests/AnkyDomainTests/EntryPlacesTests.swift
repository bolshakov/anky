import AnkyDomain
import Foundation
import Testing

struct EntryPlacesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft(kind: EntryKind) throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = kind
        draft.togglePlace(PlaceID(rawValue: "lower"))
        draft.togglePlace(PlaceID(rawValue: "si_l"))
        return draft
    }

    private var places: [PlaceID] {
        [PlaceID(rawValue: "lower"), PlaceID(rawValue: "si_l")]
    }

    @Test func onlyFatigueDoesNotAskWhere() {
        #expect(EntryKind.allCases.filter { !$0.asksWhere } == [.fatigue])
    }

    @Test func aPainEntryKeepsThePlacesOfItsDraft() throws {
        #expect(try Entry(draft: draft(kind: .pain)).places == places)
    }

    @Test func aStiffnessEntryKeepsThePlacesOfItsDraft() throws {
        #expect(try Entry(draft: draft(kind: .stiffness)).places == places)
    }

    @Test func aFatigueEntryDropsThePlacesOfItsDraft() throws {
        #expect(try Entry(draft: draft(kind: .fatigue)).places.isEmpty)
    }

    @Test func anEntryReadsAMissingPlacesKeyAsNoPlaces() throws {
        let json = #"{"id":"\#(UUID())","kind":"pain","severity":4,"date":0}"#
        #expect(try JSONDecoder().decode(Entry.self, from: Data(json.utf8)).places.isEmpty)
    }
}
