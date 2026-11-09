// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntryRowTextTests {
    @Test func theSpokenLabelReadsKindLevelTimeThenPlaces() {
        let label = EntryRowText.spokenLabel(kind: "Pain", time: "08:42", places: "Lower back", severity: "4 of 10")
        #expect(label == "Pain, 4 of 10, 08:42, Lower back")
    }

    @Test func aRowWithNoPlacesSkipsThePlacesPart() {
        let label = EntryRowText.spokenLabel(kind: "Fatigue", time: "08:42", places: nil, severity: "6 of 10")
        #expect(label == "Fatigue, 6 of 10, 08:42")
    }

    @Test func aRowWithNoPlaceSaidInWordsKeepsThem() {
        let label = EntryRowText.spokenLabel(kind: "Stiffness", time: "08:42", places: "No place", severity: "2 of 10")
        #expect(label == "Stiffness, 2 of 10, 08:42, No place")
    }

    @Test func aRowWithAnEmptyPlacesPartLeavesNoStrayComma() {
        let label = EntryRowText.spokenLabel(kind: "Pain", time: "08:42", places: "", severity: "4 of 10")
        #expect(label == "Pain, 4 of 10, 08:42")
    }

    @Test func aReadingSpeaksTimeKindPlacesThenLevel() {
        let label = EntryRowText.readingLabel(
            time: "08:42", kind: "Pain", places: "Lower back", severity: "4 of 10"
        )
        #expect(label == "08:42, Pain, Lower back, 4 of 10")
    }

    @Test func aReadingWithNoPlacesSkipsThePlacesPart() {
        let label = EntryRowText.readingLabel(time: "08:42", kind: "Fatigue", places: nil, severity: "6 of 10")
        #expect(label == "08:42, Fatigue, 6 of 10")
    }

    @Test func aReadingWithThreePlacesKeepsTheTimeFirstAndEveryPlaceAfterIt() {
        let places = "Neck, Lower back and Left hip"
        let label = EntryRowText.readingLabel(time: "08:42", kind: "Pain", places: places, severity: "6 of 10")
        #expect(label == "08:42, Pain, Neck, Lower back and Left hip, 6 of 10")
        #expect(RowSecondLine.text(time: "08:42", detail: places) == "08:42 · Neck, Lower back and Left hip")
    }

    @Test func aTwelveHourReadingTimeStillComesFirstInTheSpokenTextAndOnLineTwo() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 9, minute: 5)))
        let time = ClockText.text(for: date, calendar: calendar, locale: Locale(identifier: "en_US"))
        #expect(time == "9:05\u{202F}AM")
        let label = EntryRowText.readingLabel(time: time, kind: "Pain", places: "Lower back", severity: "4 of 10")
        #expect(label == "9:05\u{202F}AM, Pain, Lower back, 4 of 10")
        #expect(RowSecondLine.text(time: time, detail: "Lower back") == "9:05\u{202F}AM · Lower back")
    }

    @Test func aReadingOptionValueIsTimePlacesThenLevelWithoutTheKind() {
        let value = EntryRowText.readingOptionValue(time: "08:42", places: "Lower back", severity: "4 of 10")
        #expect(value == "08:42, Lower back, 4 of 10")
    }

    @Test func aReadingOptionWithNoPlacesSkipsThePlacesPart() {
        #expect(EntryRowText.readingOptionValue(time: "08:42", places: nil, severity: "6 of 10") == "08:42, 6 of 10")
    }
}
