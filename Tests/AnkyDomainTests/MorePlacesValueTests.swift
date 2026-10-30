import AnkyDomain
import Testing

struct MorePlacesValueTests {
    private let chips = ["neck", "upper", "lower", "si_l", "si_r"].map { PlaceID(rawValue: $0) }

    private func ids(_ raw: [String]) -> [PlaceID] {
        raw.map { PlaceID(rawValue: $0) }
    }

    @Test func noPlaceOutsideTheChipsIsNone() {
        let value = MorePlacesValue(selected: [], chips: chips)
        #expect(value.all.isEmpty)
        #expect(value.more == 0)
    }

    @Test func onePlaceOutsideTheChipsIsListed() {
        let value = MorePlacesValue(selected: ids(["hip_l"]), chips: chips)
        #expect(value.names == ids(["hip_l"]))
        #expect(value.more == 0)
    }

    @Test func twoPlacesOutsideTheChipsAreBothListed() {
        let value = MorePlacesValue(selected: ids(["knee_l", "hip_l"]), chips: chips)
        #expect(value.names == ids(["hip_l", "knee_l"]))
        #expect(value.more == 0)
    }

    @Test func threePlacesShowTwoNamesAndOneMore() {
        let value = MorePlacesValue(selected: ids(["hip_l", "knee_l", "ankle_l"]), chips: chips)
        #expect(value.names == ids(["hip_l", "knee_l"]))
        #expect(value.more == 1)
    }

    @Test func morePlacesCountsEveryPlaceAfterTheFirstTwo() {
        let value = MorePlacesValue(selected: ids(["hip_l", "knee_l", "ankle_l", "foot_l"]), chips: chips)
        #expect(value.names == ids(["hip_l", "knee_l"]))
        #expect(value.more == 2)
        #expect(value.all.count == 4)
    }

    @Test func placesOutsideTheChipsFollowBodyOrder() {
        let value = MorePlacesValue(selected: ids(["ankle_l", "hip_l", "knee_l"]), chips: chips)
        #expect(value.all == ids(["hip_l", "knee_l", "ankle_l"]))
    }

    @Test func aPickedPlaceWithAChipIsNotInTheValue() {
        let value = MorePlacesValue(selected: ids(["lower", "hip_l"]), chips: chips)
        #expect(value.all == ids(["hip_l"]))
    }

    @Test func anUnknownIdIsNotInTheValue() {
        let value = MorePlacesValue(selected: ids(["made_up", "hip_l"]), chips: chips)
        #expect(value.all == ids(["hip_l"]))
        #expect(value.more == 0)
    }
}
