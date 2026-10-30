import AnkyDomain
import Foundation
import Testing

struct PlaceChipsTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ places: [String], kind: EntryKind = .pain) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = kind
        draft.places = ids(places)
        return Entry(draft: draft)
    }

    private func logged(_ place: String, times: Int) throws -> [Entry] {
        try (0 ..< times).map { _ in try entry([place]) }
    }

    private func ids(_ raw: [String]) -> [PlaceID] {
        raw.map { PlaceID(rawValue: $0) }
    }

    private var defaults: [PlaceID] {
        PlaceCatalog.defaultChips
    }

    @Test func withNoEntriesTheChipsAreTheFiveDefaults() {
        #expect(PlaceChips.ranked(from: []) == defaults)
    }

    @Test func theFiveMostLoggedPlacesBecomeTheChips() throws {
        let entries = try logged("hip_l", times: 3) + logged("wrist_r", times: 2) + logged("knee_l", times: 2)
            + [entry(["eyes"]), entry(["jaw"]), entry(["ankle_r"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["hip_l", "wrist_r", "knee_l", "ankle_r", "jaw"]))
    }

    @Test func aMoreLoggedPlaceComesBeforeALessLoggedOne() throws {
        let entries = try [entry(["eyes"]), entry(["eyes"]), entry(["jaw"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["eyes", "jaw", "lower", "si_l", "si_r"]))
    }

    @Test func aLeftHipLoggedMostOftenIsAmongTheFive() throws {
        let entries = try logged("hip_l", times: 3) + logged("ankle_l", times: 2)
            + [entry(["knee_r"]), entry(["wrist_l"]), entry(["eyes"]), entry(["jaw"])]
        #expect(PlaceChips.ranked(from: entries).contains(PlaceID(rawValue: "hip_l")))
    }

    @Test func tiesKeepTheDefaultOrderFirst() throws {
        let entries = try [entry(["neck"]), entry(["lower"]), entry(["tail"]), entry(["si_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["lower", "si_l", "neck", "tail", "si_r"]))
    }

    @Test func tiesBetweenNonDefaultPlacesKeepCatalogOrder() throws {
        let entries = try [entry(["knee_l"]), entry(["hip_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["hip_l", "knee_l", "lower", "si_l", "si_r"]))
    }

    @Test func aPlaceCountsOncePerEntry() throws {
        let entries = try [entry(["hip_l", "hip_l", "hip_l"]), entry(["knee_l"]), entry(["knee_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["knee_l", "hip_l", "lower", "si_l", "si_r"]))
    }

    @Test func fewerThanFiveLoggedPlacesAreFilledFromTheDefaultsInOrder() throws {
        let entries = try [entry(["neck"]), entry(["hip_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["neck", "hip_l", "lower", "si_l", "si_r"]))
    }

    @Test func anUnknownIdNeverBecomesAChip() throws {
        let entries = try [entry(["made_up"]), entry(["made_up"]), entry(["knee_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["knee_l", "lower", "si_l", "si_r", "neck"]))
    }

    @Test func aFatigueEntryAddsNothingToTheCounts() throws {
        let entries = try [entry(["hip_l"], kind: .fatigue), entry(["hip_l"], kind: .fatigue)]
        #expect(PlaceChips.ranked(from: entries) == defaults)
    }

    @Test func theResultAlwaysHasFivePlaces() throws {
        let samples = try [[], [entry(["neck"])], PlaceCatalog.allPlaces.map { try entry([$0.rawValue]) }]
        for entries in samples {
            let chips = PlaceChips.ranked(from: entries)
            #expect(chips.count == 5)
            #expect(Set(chips).count == 5)
        }
    }

    @Test func shownKeepsTheRankedFiveWhenNothingElseIsSelected() {
        #expect(PlaceChips.shown(ranked: defaults, selected: []) == defaults)
    }

    @Test func aSelectedPlaceOutsideTheFiveIsAppendedAfterThem() {
        #expect(PlaceChips.shown(ranked: defaults, selected: ids(["hip_l"])) == defaults + ids(["hip_l"]))
    }

    @Test func aSelectedPlaceInsideTheFiveAddsNothing() {
        #expect(PlaceChips.shown(ranked: defaults, selected: ids(["lower", "neck"])) == defaults)
    }

    @Test func appendedPlacesFollowCatalogOrder() {
        let shown = PlaceChips.shown(ranked: defaults, selected: ids(["wrist_r", "hip_l"]))
        #expect(shown == defaults + ids(["hip_l", "wrist_r"]))
    }

    @Test func anUnknownSelectedIdIsNotShown() {
        let shown = PlaceChips.shown(ranked: defaults, selected: ids(["made_up", "hip_l"]))
        #expect(shown == defaults + ids(["hip_l"]))
    }
}
