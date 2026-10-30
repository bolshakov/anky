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

    private func ids(_ raw: [String]) -> [PlaceID] {
        raw.map { PlaceID(rawValue: $0) }
    }

    private var presets: [PlaceID] {
        ids(["neck", "upper", "lower", "si_l", "si_r"])
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

    @Test func aFatigueEntryAddsNothingToTheCounts() throws {
        let entries = try [entry(["hip_l"], kind: .fatigue), entry(["hip_l"], kind: .fatigue)]
        #expect(PlaceChips.chips(from: entries) == presets)
    }

    @Test func theResultAlwaysHasFivePlaces() throws {
        let samples = try [[], [entry(["neck"])], PlaceCatalog.allPlaces.map { try entry([$0.rawValue]) }]
        for entries in samples {
            let chips = PlaceChips.chips(from: entries)
            #expect(chips.count == 5)
            #expect(Set(chips).count == 5)
        }
    }
}
