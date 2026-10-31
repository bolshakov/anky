// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct RecentEntryNamesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(level)), date: date)
        draft.kind = kind
        draft.places = places.map { PlaceID(rawValue: $0) }
        return Entry(draft: draft)
    }

    private func recent(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> RecentEntry {
        try RecentEntry(entry(places, kind: kind, level: level))
    }

    private func place(_ raw: String) -> RecentName {
        .place(PlaceID(rawValue: raw))
    }

    @Test func twoNamesShowWithNoCount() throws {
        let chip = try recent(["lower", "neck"])
        #expect(chip.shownNames.count == 2)
        #expect(chip.hiddenCount == 0)
    }

    @Test func threeNamesShowTwoAndCountOne() throws {
        let chip = try recent(["neck", "upper", "lower"])
        #expect(chip.shownNames == [place("neck"), place("upper")])
        #expect(chip.hiddenCount == 1)
    }

    @Test func fourNamesShowTwoAndCountTwo() throws {
        let chip = try recent(["hip_l", "neck", "lower", "upper"])
        #expect(chip.shownNames == [place("neck"), place("upper")])
        #expect(chip.hiddenCount == 2)
    }

    @Test func aPairCountsAsOneName() throws {
        let chip = try recent(["lower", "si_l", "si_r", "knee_l"])
        #expect(chip.names.count == 3)
        #expect(chip.shownNames.count == 2)
        #expect(chip.hiddenCount == 1)
    }

    @Test func theFullListKeepsEveryPlace() throws {
        let chip = try recent(["hip_l", "neck", "lower", "upper"])
        #expect(chip.places == ["neck", "upper", "lower", "hip_l"].map { PlaceID(rawValue: $0) })
        #expect(chip.shownNames.count == 2)
    }

    @Test func bothSidesOfAPairReadAsThePair() throws {
        #expect(try recent(["si_l", "si_r"]).names == [.pair(.siJoint)])
        #expect(try recent(["knee_l", "knee_r"]).names == [.pair(.knee)])
    }

    @Test func oneSideOfAPairStaysThatPlace() throws {
        #expect(try recent(["si_l"]).names == [place("si_l")])
    }

    @Test func thePairStandsWhereItsFirstSideStood() throws {
        let chip = try recent(["lower", "si_l", "si_r", "knee_l"])
        #expect(chip.names == [place("lower"), .pair(.siJoint), place("knee_l")])
    }

    @Test func twoPairsAreTwoNames() throws {
        let chip = try recent(["si_l", "si_r", "knee_l", "knee_r"])
        #expect(chip.names == [.pair(.siJoint), .pair(.knee)])
    }

    @Test func leftAndRightOfDifferentJointsDoNotPair() throws {
        #expect(try recent(["si_l", "knee_r"]).names == [place("si_l"), place("knee_r")])
    }

    @Test func painShowsNoKind() throws {
        #expect(try recent(["lower"], kind: .pain).showsKind == false)
    }

    @Test func stiffnessShowsItsKind() throws {
        let chip = try recent(["lower"], kind: .stiffness)
        #expect(chip.showsKind == true)
        #expect(chip.shownNames.count == 1)
    }

    @Test func fatigueShowsItsKindAndNoPlaces() throws {
        let chip = try recent([], kind: .fatigue)
        #expect(chip.showsKind == true)
        #expect(chip.names.isEmpty)
        #expect(chip.showsNoPlace == false)
    }

    @Test func aPainEntryWithNoPlaceReadsNoPlace() throws {
        let chip = try recent([], kind: .pain)
        #expect(chip.showsNoPlace == true)
        #expect(chip.shownNames.isEmpty)
    }

    @Test func aStiffnessEntryWithNoPlaceReadsNoPlace() throws {
        let chip = try recent([], kind: .stiffness)
        #expect(chip.showsNoPlace == true)
        #expect(chip.shownNames.isEmpty)
    }
}
