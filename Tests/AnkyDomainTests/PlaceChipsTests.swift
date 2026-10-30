import AnkyDomain
import Foundation
import Testing

struct PlaceChipsTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ places: [String], kind: EntryKind = .pain, at minutes: Int = 0) throws -> Entry {
        var draft = try EntryDraft(
            severity: #require(Severity(4)),
            date: date.addingTimeInterval(TimeInterval(minutes * 60))
        )
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

    private var presets: [PlaceID] {
        ids(["neck", "upper", "lower", "si_l", "si_r"])
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

    @Test func fewerThanFiveLoggedPlacesAreFilledFromTheDefaultsInOrder() throws {
        let entries = try [entry(["neck"]), entry(["hip_l"])]
        #expect(PlaceChips.ranked(from: entries) == ids(["neck", "hip_l", "lower", "si_l", "si_r"]))
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

    @Test func withNoEntriesTheChipsAreTheFivePresetsInBodyOrder() {
        #expect(PlaceChips.chips(from: []) == ids(["neck", "upper", "lower", "si_l", "si_r"]))
    }

    @Test func aNewUserWithOneEntryGetsTheFivePresets() throws {
        #expect(try PlaceChips.chips(from: [entry(["lower", "si_l", "si_r"])]) == presets)
    }

    @Test func theTopFiveByCountShowInBodyOrder() throws {
        let plain = try (0 ..< 6).map { _ in try entry(["lower", "si_l", "si_r"]) }
        let entries = try [entry(["lower", "si_l", "si_r", "neck"]), entry(["lower", "si_l", "si_r", "neck"])]
            + plain
            + [entry(["lower", "neck", "knee_l", "upper"]), entry(["knee_l"])]
        #expect(PlaceChips.chips(from: entries) == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }

    @Test func onlyTheLastTenEntriesWithAPlaceCount() throws {
        let knee = try (2 ... 10).map { try entry(["knee_l"], at: $0) }
        let hip = try [entry(["hip_l"], at: 1), entry(["hip_l"], at: 0)]
        #expect(PlaceChips.chips(from: knee + hip) == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }

    @Test func anEntryWithNoPlaceDoesNotUseUpOneOfTheTen() throws {
        let hip = try [entry(["hip_l"], at: 0), entry(["hip_l"], at: 1)]
        let knee = try (2 ... 9).map { try entry(["knee_l"], at: $0) }
        let withoutPlaces = try [entry([], at: 10), entry(["knee_l"], kind: .fatigue, at: 11)]
        #expect(PlaceChips.chips(from: hip + knee + withoutPlaces) == ids(["lower", "si_l", "si_r", "hip_l", "knee_l"]))
    }

    @Test func aPlaceCountsOncePerEntry() throws {
        #expect(try PlaceChips.chips(from: [entry(["hip_l", "hip_l"])]) == presets)
    }

    @Test func leftAndRightCountSeparately() throws {
        let entries = try [entry(["knee_l"]), entry(["knee_l"]), entry(["knee_r"])]
        #expect(PlaceChips.chips(from: entries) == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }

    @Test func aPlaceNeedsACountOfTwo() throws {
        #expect(try PlaceChips.chips(from: [entry(["hip_l"])]) == presets)
    }

    @Test func aTieGoesToTheMostRecentUse() throws {
        let steady = try (0 ..< 3).map { _ in try entry(["hip_l", "shoulder_l", "knee_l", "ankle_l"]) }
        let withElbow = ids(["hip_l", "shoulder_l", "elbow_l", "knee_l", "ankle_l"])
        let withWrist = ids(["hip_l", "shoulder_l", "wrist_l", "knee_l", "ankle_l"])
        let elbowFirst = try [entry(["elbow_l"], at: 30), entry(["elbow_l"], at: 5)]
        let wristLast = try [entry(["wrist_l"], at: 10), entry(["wrist_l"], at: 20)]
        #expect(PlaceChips.chips(from: steady + elbowFirst + wristLast) == withElbow)
        let sameDate = try [entry(["elbow_l"]), entry(["wrist_l"]), entry(["elbow_l"]), entry(["wrist_l"])]
        #expect(PlaceChips.chips(from: steady + sameDate) == withWrist)
    }

    @Test func freeSlotsFillFromThePresetsInOrderSkippingChosenPlaces() throws {
        let entries = try [entry(["si_l", "hip_l", "knee_l"]), entry(["si_l", "hip_l", "knee_l"])]
        #expect(PlaceChips.chips(from: entries) == ids(["lower", "si_l", "si_r", "hip_l", "knee_l"]))
    }

    @Test func theChipsShowInBodyOrder() throws {
        let entries = try [entry(["knee_l", "neck"]), entry(["knee_l", "neck"]), entry(["knee_l"])]
        #expect(PlaceChips.chips(from: entries) == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }

    @Test func anUnknownIdNeverBecomesAChip() throws {
        let entries = try [entry(["made_up"]), entry(["made_up"]), entry(["knee_l"]), entry(["knee_l"])]
        #expect(PlaceChips.chips(from: entries) == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }
}
