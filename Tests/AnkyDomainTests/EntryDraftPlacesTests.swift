import AnkyDomain
import Foundation
import Testing

struct EntryDraftPlacesTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let lower = PlaceID(rawValue: "lower")
    private let siLeft = PlaceID(rawValue: "si_l")
    private let siRight = PlaceID(rawValue: "si_r")
    private let jaw = PlaceID(rawValue: "jaw")
    private let unknown = PlaceID(rawValue: "tentacle")

    private func newDraft() throws -> EntryDraft {
        try EntryDraft(severity: #require(Severity(4)), date: date)
    }

    @Test func aNewDraftHasNoPlaces() throws {
        let draft = try newDraft()
        #expect(draft.places.isEmpty)
        #expect(draft.placeCount == 0)
    }

    @Test func togglingAPlaceAddsItAndTogglingAgainRemovesIt() throws {
        var draft = try newDraft()
        draft.togglePlace(lower)
        #expect(draft.places == [lower])
        draft.togglePlace(lower)
        #expect(draft.places.isEmpty)
    }

    @Test func placesAreKeptInCatalogOrderWhateverOrderTheyWerePicked() throws {
        var draft = try newDraft()
        draft.togglePlace(jaw)
        draft.togglePlace(siLeft)
        draft.togglePlace(lower)
        #expect(draft.places == [lower, siLeft, jaw])
    }

    @Test func aPairWithBothSidesCountsTwoPlaces() throws {
        var draft = try newDraft()
        draft.togglePlace(siLeft)
        draft.togglePlace(siRight)
        #expect(draft.placeCount == 2)
    }

    @Test func anUnknownIdIsKeptButNotCounted() throws {
        var draft = try newDraft()
        draft.togglePlace(unknown)
        draft.togglePlace(lower)
        #expect(draft.places == [lower, unknown])
        #expect(draft.placeCount == 1)
    }

    @Test func choosingFatigueAndThenPainAgainKeepsTheDraftsPlaces() throws {
        var draft = try newDraft()
        draft.kind = .pain
        draft.togglePlace(lower)
        draft.kind = .fatigue
        draft.kind = .pain
        #expect(draft.places == [lower])
    }

    @Test func aDraftWithAChangedPlaceIsNotEqualToTheStartDraft() throws {
        var draft = try newDraft()
        let startDraft = draft
        draft.togglePlace(lower)
        #expect(draft != startDraft)
    }

    @Test func draftFromAnEntryHoldsItsPlaces() throws {
        var source = try newDraft()
        source.kind = .pain
        source.togglePlace(lower)
        source.togglePlace(siLeft)
        let copy = try EntryDraft(entry: Entry(draft: source))
        #expect(copy.places == [lower, siLeft])
    }

    @Test func draftFromAnEntryWithNoPlacesHasNone() throws {
        var source = try newDraft()
        source.kind = .pain
        let copy = try EntryDraft(entry: Entry(draft: source))
        #expect(copy.places.isEmpty)
    }
}
