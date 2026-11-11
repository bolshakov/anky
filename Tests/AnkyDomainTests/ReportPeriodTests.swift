// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportPeriodTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) throws -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return try #require(calendar.date(from: components))
    }

    @Test func oneMonthStartsAtTheStartOfTheSameDayAMonthBefore() throws {
        let now = try date(2026, 11, 11, 15, 30)
        #expect(try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) == date(2026, 10, 11))
    }

    @Test func threeMonthsStartsThreeCalendarMonthsBefore() throws {
        let now = try date(2026, 11, 11, 15, 30)
        #expect(try ReportPeriod.threeMonths.start(endingAt: now, calendar: calendar) == date(2026, 8, 11))
    }

    @Test func sixMonthsReachesBackIntoTheYearBefore() throws {
        let now = try date(2026, 3, 11, 8)
        #expect(try ReportPeriod.sixMonths.start(endingAt: now, calendar: calendar) == date(2025, 9, 11))
    }

    @Test func threeMonthsBeforeTheThirtyFirstOfMayLandsOnTheLastDayOfFebruary() throws {
        let now = try date(2026, 5, 31, 20)
        #expect(try ReportPeriod.threeMonths.start(endingAt: now, calendar: calendar) == date(2026, 2, 28))
    }

    @Test func oneMonthBeforeTheThirtyFirstOfMarchInALeapYearLandsOnTheTwentyNinthOfFebruary() throws {
        let now = try date(2028, 3, 31, 20)
        #expect(try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) == date(2028, 2, 29))
    }

    @Test func oneMonthBeforeTheThirtyFirstOfMarchLandsOnTheLastDayOfFebruary() throws {
        let now = try date(2026, 3, 31, 20)
        #expect(try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) == date(2026, 2, 28))
    }

    @Test func aStartAtMidnightIsThatSameMidnight() throws {
        let now = try date(2026, 11, 11)
        #expect(try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) == date(2026, 10, 11))
    }

    @Test func theStartIsInTheCalendarsTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let now = try #require(tokyo.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 1)))
        let start = ReportPeriod.oneMonth.start(endingAt: now, calendar: tokyo)
        #expect(start == tokyo.date(from: DateComponents(year: 2026, month: 10, day: 11)))
    }

    @Test func noStartIsAfterNow() throws {
        let now = try date(2026, 5, 31, 0, 1)
        for period in ReportPeriod.allCases {
            #expect(period.start(endingAt: now, calendar: calendar) < now)
        }
    }

    @Test func thePeriodsAreOrderedFromShortestToLongest() {
        #expect(ReportPeriod.allCases == [.oneMonth, .threeMonths, .sixMonths])
    }
}
