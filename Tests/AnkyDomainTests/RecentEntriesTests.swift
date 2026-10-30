import AnkyDomain
import Foundation
import Testing

struct RecentEntriesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func at(_ minutes: Int) -> Date {
        date.addingTimeInterval(TimeInterval(minutes * 60))
    }

    private func draft(_ places: [String] = [], kind: EntryKind = .pain, level: Int = 4) throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(level)), date: date)
        draft.kind = kind
        draft.places = places.map { PlaceID(rawValue: $0) }
        return draft
    }

    private func entry(_ places: [String] = [], kind: EntryKind = .pain, level: Int = 4) throws -> Entry {
        try Entry(draft: draft(places, kind: kind, level: level))
    }

    private func entry(at minutes: Int, _ places: [String] = []) throws -> Entry {
        var made = try draft(places)
        made.date = at(minutes)
        return Entry(draft: made)
    }

    private func recent(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> RecentEntry {
        try RecentEntry(entry(places, kind: kind, level: level))
    }

    @Test func entriesWithTheSameKindPlacesAndLevelCountOnce() throws {
        let entries = try [entry(["lower"]), entry(["lower"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == [recent(["lower"])])
    }

    @Test func theNoteAndTheTimeDoNotMakeEntriesDistinct() throws {
        var noted = try draft(["lower"])
        noted.note = "Walk"
        noted.date = at(5)
        let entries = try [Entry(draft: noted), entry(at: 0, ["lower"])]
        #expect(RecentEntries.distinct(from: entries, limit: 10).count == 1)
    }

    @Test func aDifferentLevelIsADifferentRecentEntry() throws {
        let entries = try [entry(["lower"], level: 4), entry(["lower"], level: 5)]
        #expect(RecentEntries.distinct(from: entries, limit: 10).count == 2)
    }

    @Test func aDifferentKindIsADifferentRecentEntry() throws {
        let entries = try [entry(["lower"], kind: .pain), entry(["lower"], kind: .stiffness)]
        #expect(RecentEntries.distinct(from: entries, limit: 10).count == 2)
    }

    @Test func aDifferentPlaceSetIsADifferentRecentEntry() throws {
        let entries = try [entry(["lower"]), entry(["lower", "neck"])]
        #expect(RecentEntries.distinct(from: entries, limit: 10).count == 2)
    }

    @Test func placesSavedInAnotherOrderAreTheSameRecentEntry() throws {
        let entries = try [entry(["si_r", "lower"]), entry(["lower", "si_r"])]
        #expect(RecentEntries.distinct(from: entries, limit: 10).count == 1)
    }

    @Test func unknownPlaceIdsDoNotMakeEntriesDistinct() throws {
        let entries = try [entry(["lower"]), entry(["lower", "not_a_place"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == [recent(["lower"])])
    }

    @Test func aFatigueEntryIgnoresItsPlaces() throws {
        let entries = try [entry(["lower"], kind: .fatigue), entry([], kind: .fatigue)]
        let distinct = RecentEntries.distinct(from: entries, limit: 10)
        #expect(distinct.count == 1)
        #expect(distinct.first?.places.isEmpty == true)
    }

    @Test func theNewestOfEqualEntriesIsTheOneKept() throws {
        let entries = try [entry(at: 0, ["lower"]), entry(at: 1, ["neck"]), entry(at: 2, ["lower"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == [recent(["lower"]), recent(["neck"])])
    }

    @Test func recentEntriesComeNewestFirst() throws {
        let entries = try [entry(at: 1, ["neck"]), entry(at: 3, ["lower"]), entry(at: 2, ["hip_l"])]
        let expected = try [recent(["lower"]), recent(["hip_l"]), recent(["neck"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == expected)
    }

    @Test func equalDatesGoToTheEntryLoggedLater() throws {
        let entries = try [entry(at: 0, ["neck"]), entry(at: 0, ["lower"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == [recent(["lower"]), recent(["neck"])])
    }

    @Test func theLimitCapsTheList() throws {
        let entries = try ["neck", "upper", "lower", "si_l", "hip_l"].enumerated().map { minute, place in
            try entry(at: minute + 1, [place])
        }
        let newest = try recent(["hip_l"])
        #expect(RecentEntries.distinct(from: entries, limit: 3).count == 3)
        #expect(RecentEntries.distinct(from: entries, limit: 1) == [newest])
    }

    @Test(arguments: [0, -1])
    func aLimitOfZeroOrLessGivesNoRecentEntries(limit: Int) throws {
        let entries = try [entry(["lower"])]
        #expect(RecentEntries.distinct(from: entries, limit: limit).isEmpty)
    }

    @Test func noEntriesGiveNoRecentEntries() {
        #expect(RecentEntries.distinct(from: [], limit: 3).isEmpty)
    }

    @Test func entriesFromEarlierDaysAreRecentToo() throws {
        let thirtyDaysAgo = -30 * 24 * 60
        let entries = try [entry(at: thirtyDaysAgo, ["lower"])]
        #expect(try RecentEntries.distinct(from: entries, limit: 10) == [recent(["lower"])])
    }
}
