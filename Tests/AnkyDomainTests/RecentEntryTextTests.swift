import AnkyDomain
import Foundation
import Testing

struct RecentEntryTextTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private var words: RecentWords {
        RecentWords(
            kind: { $0.rawValue.capitalized },
            name: { Self.standInName($0) },
            level: { "\($0.value) of 10" },
            noPlace: "No place"
        )
    }

    private static func standInName(_ name: RecentName) -> String {
        switch name {
        case let .place(id): placeName(id.rawValue)
        case .pair(.siJoint): "SI joints"
        case .pair(.knee): "Knees"
        case let .pair(joint): joint.rawValue
        }
    }

    private static func placeName(_ raw: String) -> String {
        switch raw {
        case "neck": "Neck"
        case "lower": "Lower back"
        case "si_l": "Left SI joint"
        case "knee_l": "Left knee"
        default: raw
        }
    }

    private func entry(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(level)), date: date)
        draft.kind = kind
        draft.places = places.map { PlaceID(rawValue: $0) }
        return Entry(draft: draft)
    }

    private func recent(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> RecentEntry {
        try RecentEntry(entry(places, kind: kind, level: level))
    }

    @Test func aPainChipHasNoKindPrefix() throws {
        #expect(try recent(["lower", "si_l", "si_r"]).chipText(words: words) == "Lower back, SI joints · 4")
    }

    @Test func aStiffnessChipReadsKindPlacesLevel() throws {
        #expect(try recent(["lower"], kind: .stiffness).chipText(words: words) == "Stiffness · Lower back · 4")
    }

    @Test func aFatigueChipReadsKindAndLevel() throws {
        #expect(try recent([], kind: .fatigue).chipText(words: words) == "Fatigue · 4")
    }

    @Test func aChipWithNoPlaceReadsNoPlaceAndTheLevel() throws {
        #expect(try recent([]).chipText(words: words) == "No place · 4")
        #expect(try recent([], kind: .stiffness).chipText(words: words) == "Stiffness · No place · 4")
    }

    @Test func aLongListChipReadsTwoNamesAndACount() throws {
        #expect(try recent(["neck", "lower", "hip_l", "knee_l"]).chipText(words: words) == "Neck, Lower back +2 · 4")
    }

    @Test func aPairChipReadsTheStandInPluralName() throws {
        #expect(try recent(["si_l", "si_r"]).chipText(words: words) == "SI joints · 4")
    }

    @Test func oneSideOfAPairReadsThatPlaceInTheChip() throws {
        #expect(try recent(["si_l"]).chipText(words: words) == "Left SI joint · 4")
    }

    @Test func theSpokenTextHoldsEveryNameAndTheKind() throws {
        let chip = try recent(["neck", "lower", "si_l", "si_r", "knee_l"])
        #expect(chip.spokenText(words: words) == "Pain, Neck, Lower back, SI joints, Left knee, 4 of 10")
    }

    @Test func theSpokenTextOfAFatigueEntryHasNoPlace() throws {
        #expect(try recent([], kind: .fatigue).spokenText(words: words) == "Fatigue, 4 of 10")
    }

    @Test func theSpokenTextOfAnEntryWithNoPlaceSaysNoPlace() throws {
        #expect(try recent([], kind: .stiffness).spokenText(words: words) == "Stiffness, No place, 4 of 10")
    }
}
