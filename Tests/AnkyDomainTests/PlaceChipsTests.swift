// SPDX-License-Identifier: GPL-3.0-or-later
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

    private func regulars() throws -> [Entry] {
        try (0 ..< 3).map { _ in try entry(["hip_l", "knee_l", "ankle_l", "elbow_l"]) }
    }

    @Test func twoPinsAndNoEntriesGiveThePinsAndTheFirstThreePresets() {
        let chips = PlaceChips.chips(from: [], pinned: ids(["tail", "jaw"]))
        #expect(chips == ids(["lower", "tail", "si_l", "si_r", "jaw"]))
    }

    @Test func aPinnedPlaceIsNotChosenAgainByTheUsageRule() throws {
        let used = ["knee_l", "hip_l", "hip_r", "ribs", "chest", "elbow_l"]
        let entries = try [entry(used), entry(used), entry(["knee_l"]), entry(["knee_l"])]
        let chips = PlaceChips.chips(from: entries, pinned: ids(["knee_l"]))
        #expect(chips == ids(["hip_l", "hip_r", "ribs", "chest", "knee_l"]))
    }

    @Test func aPinnedPlaceThatIsAlsoAPresetIsNotCountedTwice() {
        let chips = PlaceChips.chips(from: [], pinned: ids(["lower", "tail"]))
        #expect(chips == ids(["neck", "lower", "tail", "si_l", "si_r"]))
    }

    @Test func pinsComeBeforeAPlaceUsedManyTimes() throws {
        let steady = try (0 ..< 5).map { _ in try entry(["hip_l", "elbow_l", "wrist_l", "knee_l", "ankle_l"]) }
        let chips = PlaceChips.chips(from: steady, pinned: ids(["jaw"]))
        #expect(chips == ids(["hip_l", "elbow_l", "wrist_l", "knee_l", "jaw"]))
    }

    @Test func anUnknownPinNeverBecomesAChip() {
        let chips = PlaceChips.chips(from: [], pinned: ids(["made_up", "tail"]))
        #expect(chips == ids(["neck", "lower", "tail", "si_l", "si_r"]))
    }

    @Test func withNoPinsAndNoLastChipsTheChipsAreTheOldOnes() throws {
        let plain = try (0 ..< 6).map { _ in try entry(["lower", "si_l", "si_r"]) }
        let entries = try [entry(["lower", "si_l", "si_r", "neck"]), entry(["lower", "si_l", "si_r", "neck"])]
            + plain
            + [entry(["lower", "neck", "knee_l", "upper"]), entry(["knee_l"])]
        let chips = PlaceChips.chips(from: entries, pinned: [], lastChips: [])
        #expect(chips == ids(["neck", "lower", "si_l", "si_r", "knee_l"]))
    }

    @Test func fivePinsAreTheChipsWhateverTheLastTenEntriesHold() throws {
        let heavy = try (0 ..< 3).map { _ in try entry(["neck", "upper", "lower", "si_l", "si_r"]) }
        let chips = PlaceChips.chips(from: heavy, pinned: ids(["tail", "jaw", "hip_l", "knee_l", "eyes"]))
        #expect(chips == ids(["tail", "hip_l", "knee_l", "jaw", "eyes"]))
    }

    @Test func morePinsThanFiveKeepOnlyTheFirstFivePinned() {
        let chips = PlaceChips.chips(from: [], pinned: ids(["tail", "jaw", "hip_l", "knee_l", "eyes", "ribs"]))
        #expect(chips == ids(["tail", "hip_l", "knee_l", "jaw", "eyes"]))
    }

    @Test func theUsageRuleStillFillsTheCardAroundOnePin() throws {
        let entries = try [entry(["hip_l", "knee_l"]), entry(["hip_l", "knee_l"])]
        let chips = PlaceChips.chips(from: entries, pinned: ids(["jaw"]))
        #expect(chips == ids(["lower", "si_l", "hip_l", "knee_l", "jaw"]))
    }

    @Test func aTieGoesToThePlaceThatWasAChipLastTime() throws {
        let tied = try [entry(["wrist_l", "shoulder_l"], at: 100), entry(["wrist_l", "shoulder_l"], at: 110)]
        let chips = try PlaceChips.chips(from: regulars() + tied, lastChips: ids(["wrist_l"]))
        #expect(chips == ids(["hip_l", "elbow_l", "wrist_l", "knee_l", "ankle_l"]))
    }

    @Test func lastTimeBeatsTheMostRecentUseInATie() throws {
        let shoulderLast = try [entry(["shoulder_l"], at: 10), entry(["shoulder_l"], at: 20)]
        let wristRecent = try [entry(["wrist_l"], at: 100), entry(["wrist_l"], at: 120)]
        let chips = try PlaceChips.chips(from: regulars() + shoulderLast + wristRecent, lastChips: ids(["shoulder_l"]))
        #expect(chips == ids(["hip_l", "shoulder_l", "elbow_l", "knee_l", "ankle_l"]))
    }

    @Test func ifBothWereChipsLastTimeTheMostRecentUseWins() throws {
        let shoulderLast = try [entry(["shoulder_l"], at: 10), entry(["shoulder_l"], at: 20)]
        let wristRecent = try [entry(["wrist_l"], at: 100), entry(["wrist_l"], at: 120)]
        let lastChips = ids(["shoulder_l", "wrist_l"])
        let chips = try PlaceChips.chips(from: regulars() + shoulderLast + wristRecent, lastChips: lastChips)
        #expect(chips == ids(["hip_l", "elbow_l", "wrist_l", "knee_l", "ankle_l"]))
    }

    @Test func aStillTiedPairGoesToBodyOrder() throws {
        let tied = try [entry(["wrist_l", "shoulder_l"], at: 100), entry(["wrist_l", "shoulder_l"], at: 110)]
        let chips = try PlaceChips.chips(from: regulars() + tied)
        #expect(chips == ids(["hip_l", "shoulder_l", "elbow_l", "knee_l", "ankle_l"]))
    }

    @Test func aPlaceThatWasAChipButHasOneUseIsNotKept() throws {
        let once = try [entry(["ribs"], at: 100)]
        let chips = try PlaceChips.chips(from: regulars() + once, lastChips: ids(["ribs"]))
        #expect(chips == ids(["lower", "hip_l", "elbow_l", "knee_l", "ankle_l"]))
    }

    @Test func pinsShowInBodyOrderNotInPinOrder() {
        let chips = PlaceChips.chips(from: [], pinned: ids(["jaw", "tail"]))
        #expect(chips == ids(["lower", "tail", "si_l", "si_r", "jaw"]))
    }
}
