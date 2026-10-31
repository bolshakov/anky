// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PlaceCatalogTests {
    @Test func theCatalogListsExactlyTheTwentyEightIds() {
        let spine = ["neck", "upper", "lower", "tail"]
        let pelvisAndChest = ["si_l", "si_r", "hip_l", "hip_r", "ribs", "chest"]
        let arms = ["shoulder_l", "shoulder_r", "elbow_l", "elbow_r", "wrist_l", "wrist_r", "hand_l", "hand_r"]
        let legs = ["knee_l", "knee_r", "ankle_l", "ankle_r", "foot_l", "foot_r", "heel_l", "heel_r"]
        let head = ["jaw", "eyes"]
        let expected = spine + pelvisAndChest + arms + legs + head
        #expect(PlaceCatalog.allPlaces.map(\.rawValue) == expected)
    }

    @Test func placeIdsAreUnique() {
        let ids = PlaceCatalog.allPlaces.map(\.rawValue)
        #expect(ids.count == 28)
        #expect(Set(ids).count == ids.count)
    }

    @Test func theFiveGroupsHoldTwoOrFourJointsEach() {
        let counts = PlaceGroup.allCases.map { PlaceCatalog.joints(in: $0).count }
        #expect(counts == [4, 4, 4, 4, 2])
        #expect(counts.reduce(0, +) == 18)
    }

    @Test func pairedJointsGetALeftAndARightId() {
        #expect(Joint.siJoint.places == [PlaceID(rawValue: "si_l"), PlaceID(rawValue: "si_r")])
        #expect(Joint.knee.places == [PlaceID(rawValue: "knee_l"), PlaceID(rawValue: "knee_r")])
    }

    @Test func singleJointsUseTheirStemAsTheId() {
        #expect(Joint.lowerBack.places == [PlaceID(rawValue: "lower")])
        #expect(Joint.ribs.places == [PlaceID(rawValue: "ribs")])
        #expect(Joint.jaw.places == [PlaceID(rawValue: "jaw")])
    }

    @Test func theIdsTheTicketNamesAreExact() {
        let ids = Set(PlaceCatalog.allPlaces.map(\.rawValue))
        #expect(ids.contains("lower"))
        #expect(ids.contains("si_l"))
        #expect(ids.contains("hip_r"))
        #expect(ids.contains("jaw"))
    }

    @Test func theDefaultChipsAreLowerBackThenBothSiJointsThenNeckThenUpperBack() {
        #expect(PlaceCatalog.defaultChips.map(\.rawValue) == ["lower", "si_l", "si_r", "neck", "upper"])
    }

    @Test func everyDefaultChipIsInTheCatalog() {
        let chips = PlaceCatalog.defaultChips
        #expect(chips.count == 5)
        #expect(chips.allSatisfy { PlaceCatalog.allPlaces.contains($0) })
    }

    @Test func aPlaceLooksUpItsJointAndSide() {
        let hipRight = PlaceID(rawValue: "hip_r")
        let jaw = PlaceID(rawValue: "jaw")
        #expect(PlaceCatalog.joint(of: hipRight) == .hip)
        #expect(PlaceCatalog.side(of: hipRight) == .right)
        #expect(PlaceCatalog.joint(of: jaw) == .jaw)
        #expect(PlaceCatalog.side(of: jaw) == nil)
    }

    @Test func anUnknownIdHasNoJointAndNoSide() {
        let tentacle = PlaceID(rawValue: "tentacle")
        #expect(PlaceCatalog.joint(of: tentacle) == nil)
        #expect(PlaceCatalog.side(of: tentacle) == nil)
    }

    @Test func aPlaceIdEncodesAsAPlainString() throws {
        let data = try JSONEncoder().encode([PlaceID(rawValue: "lower")])
        #expect(String(data: data, encoding: .utf8) == #"["lower"]"#)
        #expect(try JSONDecoder().decode([PlaceID].self, from: data) == [PlaceID(rawValue: "lower")])
    }
}
