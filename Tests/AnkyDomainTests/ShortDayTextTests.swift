// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ShortDayTextTests {
    private let calendar: Calendar
    private let newYear: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        newYear = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 0, minute: 10)))
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) throws -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return try #require(calendar.date(from: parts))
    }

    private func day(_ date: Date, now: Date, _ identifier: String = "en_GB") -> ShortDay {
        ShortDayText.day(for: date, now: now, calendar: calendar, locale: Locale(identifier: identifier))
    }

    @Test func aMomentEarlierTodayIsToday() throws {
        #expect(try day(moment(2027, 1, 1, 0, 5), now: newYear) == .today)
    }

    @Test func theLastMinuteOfTheYearBeforeIsYesterdayNotAnotherYear() throws {
        #expect(try day(moment(2026, 12, 31, 23, 55), now: newYear) == .yesterday)
    }

    @Test func aDayTwoBackInTheOldYearReadsItsDayAndYear() throws {
        #expect(try day(moment(2026, 12, 30), now: newYear) == .otherYear(day: "Wed 30 Dec", year: "2026"))
    }

    @Test func yesterdayInTheSameYearIsYesterday() throws {
        let now = try moment(2026, 11, 1, 0, 10)
        #expect(try day(moment(2026, 10, 31, 23, 50), now: now) == .yesterday)
    }

    @Test func aDayEarlierInTheSameYearReadsItsDayOnly() throws {
        let now = try moment(2026, 11, 1)
        #expect(try day(moment(2026, 10, 24), now: now) == .sameYear("Sat 24 Oct"))
    }

    @Test func theEnglishUnitedStatesReadsTheDayWithItsComma() throws {
        let now = try moment(2026, 11, 1)
        #expect(try day(moment(2026, 10, 24), now: now, "en_US") == .sameYear("Sat, Oct 24"))
    }

    @Test func theDayIsReadInTheCalendarsTimeZone() throws {
        // Both moments are 1 November in Auckland but fall on different days in UTC and Berlin.
        let now = try moment(2026, 11, 1, 23)
        #expect(try day(moment(2026, 11, 1, 0, 30), now: now) == .today)
    }
}
