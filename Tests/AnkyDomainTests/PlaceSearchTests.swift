import AnkyDomain
import Foundation
import Testing

struct PlaceSearchTests {
    private func search(
        _ query: String,
        jointNames: [Joint: String] = [:],
        groupNames: [PlaceGroup: String] = [:]
    ) -> [Joint] {
        PlaceSearch.joints(
            matching: query,
            jointName: { jointNames[$0, default: ""] },
            groupName: { groupNames[$0, default: ""] }
        )
    }

    @Test func anEmptyQueryListsEveryJointInCatalogOrder() {
        #expect(search("") == Joint.allCases)
    }

    @Test func aJointNameFindsThatJoint() {
        #expect(search("knee", jointNames: [.knee: "Knee"]) == [.knee])
    }

    @Test func searchIgnoresCaseAndSpaces() {
        #expect(search("  KNEE ", jointNames: [.knee: "Knee"]) == [.knee])
    }

    @Test func searchIgnoresAccents() {
        #expect(search("génou", jointNames: [.knee: "Genou"]) == [.knee])
    }

    @Test func aGroupNameListsTheWholeGroup() {
        #expect(search("legs", groupNames: [.legs: "Legs"]) == [.knee, .ankle, .foot, .heel])
    }

    @Test func theQueryHeadFindsTheHeadGroup() {
        #expect(search("head", groupNames: [.head: "Head"]) == [.jaw, .eyes])
    }

    @Test func resultsKeepCatalogOrderAndHoldEachJointOnce() {
        let result = search(
            "chest",
            jointNames: [.chestWall: "Chest wall"],
            groupNames: [.pelvisAndChest: "Pelvis and chest"]
        )
        #expect(result == [.siJoint, .hip, .ribs, .chestWall])
    }

    @Test func aQueryWithNoMatchFindsNothing() {
        #expect(search("tentacle", jointNames: [.knee: "Knee"], groupNames: [.legs: "Legs"]).isEmpty)
    }
}
