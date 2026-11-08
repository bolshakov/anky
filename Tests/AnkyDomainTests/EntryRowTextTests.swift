// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct EntryRowTextTests {
    @Test func theSpokenLabelReadsKindTimePlacesThenLevel() {
        let label = EntryRowText.spokenLabel(kind: "Pain", time: "08:42", places: "Lower back", severity: "4 of 10")
        #expect(label == "Pain, 08:42, Lower back, 4 of 10")
    }

    @Test func aRowWithNoPlacesSkipsThePlacesPart() {
        let label = EntryRowText.spokenLabel(kind: "Fatigue", time: "08:42", places: nil, severity: "6 of 10")
        #expect(label == "Fatigue, 08:42, 6 of 10")
    }

    @Test func aRowWithNoPlaceSaidInWordsKeepsThem() {
        let label = EntryRowText.spokenLabel(kind: "Stiffness", time: "08:42", places: "No place", severity: "2 of 10")
        #expect(label == "Stiffness, 08:42, No place, 2 of 10")
    }
}
