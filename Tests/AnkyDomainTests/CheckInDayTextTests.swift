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
        takenAt = newYear
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
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
            onDay: { name, day, time in "After your \(name) on \(day) at \(time)" },
            yearDay: { day, year in "\(day) \(year)" }
        )
    }

    /// Each closure echoes the before reading it was given, so a test sees which reading reached which day.
    private var infoWords: CheckInInfoWords {
        CheckInInfoWords(
            today: { time, before in "Taken at \(time).\(Self.before(before))" },
            yesterday: { time, before in "Taken yesterday at \(time).\(Self.before(before))" },
            onDay: { day, time, before in "Taken on \(day) at \(time).\(Self.before(before))" },
            yearDay: { day, year in "\(day) \(year)" }
        )
    }

    private static func before(_ entry: Entry?) -> String {
        guard let entry else { return "" }
        return " Before: \(entry.kind.rawValue.capitalized) \(entry.severity.value)."
    }

    private func row(_ takenAt: Date, now: Date) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: calendar, locale: locale)
        return CheckInDayText.rowSubtitle(name: "Zorblex", time: "12:00", day: day, words: rowWords)
    }

    private func info(_ takenAt: Date, now: Date, before: Entry? = nil) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: calendar, locale: locale)
        return CheckInDayText.infoTaken(time: "12:00", day: day, before: before, words: infoWords)
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

    @Test func aDoseEarlierInTheSameYearReadsItsDay() throws {
        let now = try moment(2026, 11, 1)
        let taken = try moment(2026, 10, 24)
        #expect(row(taken, now: now) == "After your Zorblex on Sat 24 Oct at 12:00")
        #expect(info(taken, now: now) == "Taken on Sat 24 Oct at 12:00.")
    }

    @Test func aDoseFromAnotherYearReadsItsDayAndYear() throws {
        let taken = try moment(2026, 12, 30)
        #expect(row(taken, now: newYear) == "After your Zorblex on Wed 30 Dec 2026 at 12:00")
        #expect(info(taken, now: newYear) == "Taken on Wed 30 Dec 2026 at 12:00.")
    }

    @Test func aDoseTakesTheDayTheDateRowReads() throws {
        let taken = try moment(2026, 12, 30)
        let day = CheckInDayText.day(for: taken, now: newYear, calendar: calendar, locale: locale)
        #expect(day == ShortDayText.day(for: taken, now: newYear, calendar: calendar, locale: locale))
        #expect(day == .otherYear(day: "Wed 30 Dec", year: "2026"))
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
        #expect(info(sameYear, now: now, before: before) == "Taken on Sat 24 Oct at 12:00. Before: Pain 7.")
    }

    @Test func aDoseWhoseBeforeReadingIsGoneReadsAsNoEarlierReading() throws {
        let dose = Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt, beforeReadingID: UUID())
        let saved = try entry(.pain, 7)
        let readings = DoseReadings(dose, in: [saved])
        #expect(info(takenAt, now: newYear, before: readings.before) == "Taken at 12:00.")
    }
}
