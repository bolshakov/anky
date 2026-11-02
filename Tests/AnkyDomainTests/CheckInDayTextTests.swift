// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInDayTextTests {
    private let calendar: Calendar
    private let locale = Locale(identifier: "en_GB")
    private let newYear: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        newYear = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 0, minute: 10)))
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }

    private var rowWords: CheckInRowWords {
        CheckInRowWords(
            today: { name, time in "After your \(name) at \(time)" },
            yesterday: { name, time in "After your \(name) yesterday at \(time)" },
            onDay: { name, day, time in "After your \(name) on \(day) at \(time)" },
            yearDay: { day, year in "\(day) \(year)" }
        )
    }

    private var infoWords: CheckInInfoWords {
        CheckInInfoWords(
            today: { time in "Taken at \(time)." },
            yesterday: { time in "Taken yesterday at \(time)." },
            onDay: { day, time in "Taken on \(day) at \(time)." },
            yearDay: { day, year in "\(day) \(year)" }
        )
    }

    private func row(_ takenAt: Date, now: Date) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: calendar, locale: locale)
        return CheckInDayText.rowSubtitle(name: "Zorblex", time: "12:00", day: day, words: rowWords)
    }

    private func info(_ takenAt: Date, now: Date) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: calendar, locale: locale)
        return CheckInDayText.infoTaken(time: "12:00", day: day, words: infoWords)
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
}
