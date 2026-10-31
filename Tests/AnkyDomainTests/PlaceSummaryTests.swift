// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PlaceSummaryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ kind: EntryKind, places: [String]) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = kind
        draft.places = places.map { PlaceID(rawValue: $0) }
        return Entry(draft: draft)
    }

    private func place(_ rawValue: String) -> PlaceID {
        PlaceID(rawValue: rawValue)
    }

    @Test func aFatigueEntryReadsAsWholeBody() throws {
        #expect(try entry(.fatigue, places: []).placeSummary == .wholeBody)
    }

    @Test func aFatigueEntryStoredWithPlacesStillReadsAsWholeBody() throws {
        #expect(try entry(.fatigue, places: ["lower", "si_l"]).placeSummary == .wholeBody)
    }

    @Test func aPainEntryWithNoPlacesReadsAsNoPlace() throws {
        #expect(try entry(.pain, places: []).placeSummary == .noPlace)
    }

    @Test func aStiffnessEntryWithNoPlacesReadsAsNoPlace() throws {
        #expect(try entry(.stiffness, places: []).placeSummary == .noPlace)
    }

    @Test func aPainEntryListsItsPlaces() throws {
        let summary = try entry(.pain, places: ["lower", "si_l"]).placeSummary
        #expect(summary == .places([place("lower"), place("si_l")]))
    }

    @Test func bothKneesListLeftThenRight() throws {
        let summary = try entry(.pain, places: ["knee_r", "knee_l"]).placeSummary
        #expect(summary == .places([place("knee_l"), place("knee_r")]))
    }

    @Test func placesFollowCatalogOrderNotPickOrder() throws {
        let summary = try entry(.pain, places: ["jaw", "lower"]).placeSummary
        #expect(summary == .places([place("lower"), place("jaw")]))
    }

    @Test func unknownIdsAreLeftOutOfTheList() throws {
        let summary = try entry(.pain, places: ["lower", "tentacle"]).placeSummary
        #expect(summary == .places([place("lower")]))
    }

    @Test func anEntryWithOnlyUnknownIdsReadsAsNoPlace() throws {
        #expect(try entry(.pain, places: ["tentacle"]).placeSummary == .noPlace)
    }

    @Test func anEntryFromAnOldFileReadsAsNoPlace() throws {
        let json = #"{"id":"\#(UUID())","kind":"pain","severity":4,"date":0}"#
        let entry = try JSONDecoder().decode(Entry.self, from: Data(json.utf8))
        #expect(entry.placeSummary == .noPlace)
    }
}
