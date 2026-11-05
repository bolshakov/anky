// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInDayTextTests {
    private let calendar: Calendar
    private let locale = Locale(identifier: "en_GB")
    private let newYear: Date
    private let takenAt: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        newYear = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 0, minute: 10)))
        takenAt = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 12)))
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }

    private func entry(_ kind: EntryKind, _ level: Int) throws -> Entry {
        try Entry(
            id: UUID(), kind: kind, severity: #require(Severity(level)), date: takenAt, note: nil, places: []
        )
    }

    private var rowWords: CheckInRowWords {
        CheckInRowWords(
            today: { name, time in "After your \(name) at \(time)" },
            yesterday: { name, time in "After your \(name) yesterday at \(time)" },
            onDay: { name, day in "After your \(name) on \(day)" }
        )
    }

    /// Each closure echoes the before reading it was given, so a test sees which reading reached which day.
    private var infoWords: CheckInInfoWords {
        CheckInInfoWords(
            today: { time, before in "Taken at \(time).\(Self.before(before))" },
            yesterday: { time, before in "Taken yesterday at \(time).\(Self.before(before))" },
            onDay: { day, before in "Taken \(day).\(Self.before(before))" }
        )
    }

    private static func before(_ entry: Entry?) -> String {
        guard let entry else { return "" }
        return " Before: \(entry.kind.rawValue.capitalized) \(entry.severity.value)."
    }

    private func wording(_ takenAt: Date, now: Date, locale: Locale? = nil) -> DayWording {
        CheckInDayText.wording(for: takenAt, now: now, calendar: calendar, locale: locale ?? self.locale)
    }

    private func row(_ takenAt: Date, now: Date) -> String {
        CheckInDayText.rowSubtitle(name: "Zorblex", wording: wording(takenAt, now: now), words: rowWords)
    }

    private func info(_ takenAt: Date, now: Date, before: Entry? = nil) -> String {
        CheckInDayText.infoTaken(wording: wording(takenAt, now: now), before: before, words: infoWords)
    }

    @Test func aDoseEarlierTodayReadsAsToday() throws {
        let taken = try moment(2027, 1, 1)
        #expect(row(taken, now: newYear) == "After your Zorblex at 12:00")
        #expect(info(taken, now: newYear) == "Taken at 12:00.")
    }

    @Test func aDoseFromYesterdayReadsAsYesterday() throws {
        let taken = try moment(2026, 12, 31)
        #expect(row(taken, now: newYear) == "After your Zorblex yesterday at 12:00")
        #expect(info(taken, now: newYear) == "Taken yesterday at 12:00.")
    }

    @Test func aDoseLateYesterdayReadsAsYesterdayJustAfterMidnight() throws {
        let taken = try moment(2026, 12, 31, 23, 50)
        #expect(info(taken, now: newYear) == "Taken yesterday at 23:50.")
    }

    @Test func aDoseEarlierInTheSameYearReadsItsDayAndTime() throws {
        let now = try moment(2026, 11, 1)
        let taken = try moment(2026, 10, 24)
        #expect(row(taken, now: now) == "After your Zorblex on 24 Oct at 12:00")
        #expect(info(taken, now: now) == "Taken 24 Oct at 12:00.")
    }

    @Test func aDoseFromAnotherYearReadsItsDayYearAndTime() throws {
        let taken = try moment(2026, 12, 30)
        #expect(row(taken, now: newYear) == "After your Zorblex on 30 Dec 2026 at 12:00")
        #expect(info(taken, now: newYear) == "Taken 30 Dec 2026 at 12:00.")
    }

    @Test func theEnglishUnitedStatesReadsTheDayAndTimeWithItsNarrowSpaceBeforeAM() throws {
        let now = try moment(2026, 11, 1)
        let taken = try moment(2026, 10, 24, 12)
        let us = Locale(identifier: "en_US")
        let text = CheckInDayText.infoTaken(
            wording: wording(taken, now: now, locale: us),
            before: nil,
            words: infoWords
        )
        #expect(text == "Taken Oct 24 at 12:00\u{202F}PM.")
    }

    @Test func aBeforeReadingTodayNamesItsKindAndLevelAfterTheTime() throws {
        let before = try entry(.pain, 7)
        #expect(info(takenAt, now: newYear, before: before) == "Taken at 12:00. Before: Pain 7.")
    }

    @Test func aBeforeReadingIsPassedWithEveryDayWording() throws {
        let before = try entry(.pain, 7)
        let yesterday = try moment(2026, 12, 31)
        let now = try moment(2026, 11, 1)
        let sameYear = try moment(2026, 10, 24)
        #expect(info(yesterday, now: newYear, before: before) == "Taken yesterday at 12:00. Before: Pain 7.")
        #expect(info(sameYear, now: now, before: before) == "Taken 24 Oct at 12:00. Before: Pain 7.")
    }

    @Test func aDoseWhoseBeforeReadingIsGoneReadsAsNoEarlierReading() throws {
        let dose = Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt, beforeReadingID: UUID())
        let saved = try entry(.pain, 7)
        let readings = DoseReadings(dose, in: [saved])
        #expect(info(takenAt, now: newYear, before: readings.before) == "Taken at 12:00.")
    }

    @Test func theDayIsReadInTheCalendarsTimeZone() throws {
        // Both moments are 1 November in Auckland but fall on different days in UTC and Berlin.
        let now = try moment(2026, 11, 1, 23)
        #expect(try wording(moment(2026, 11, 1, 0, 30), now: now) == .today(time: "00:30"))
    }

    @Test func anHourBeforeTenReadsWithTwoDigitsAsTheSystemWritesIt() throws {
        let early = try moment(2026, 12, 31, 8, 24)
        #expect(info(early, now: newYear) == "Taken yesterday at 08:24.")
        let today = try moment(2027, 1, 1, 8, 24)
        #expect(info(today, now: newYear) == "Taken at 08:24.")
        let us = Locale(identifier: "en_US")
        let text = CheckInDayText.infoTaken(
            wording: wording(early, now: newYear, locale: us),
            before: nil,
            words: infoWords
        )
        #expect(text == "Taken yesterday at 8:24\u{202F}AM.")
    }
}
