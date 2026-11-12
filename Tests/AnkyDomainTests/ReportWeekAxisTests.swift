// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportWeekAxisTests {
    private static func calendar(_ locale: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }

    private let american = Self.calendar("en_US")
    private let british = Self.calendar("en_GB")

    @Test(arguments: [(0, 1), (1, 1), (14, 1), (15, 2), (27, 2), (28, 2)])
    func theStrideIsOneUpToFourteenWeeksAndTwoAbove(weekCount: Int, stride: Int) {
        #expect(ReportWeekAxis.labelStride(weekCount: weekCount) == stride)
    }

    @Test func noWeeksGiveNoLabels() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 0).isEmpty)
    }

    @Test func oneWeekIsLabelled() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 1) == [0])
    }

    @Test func fourteenWeeksAreEachLabelled() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 14) == Array(0 ..< 14))
    }

    @Test func fifteenWeeksLabelEverySecondWeekFromTheFirst() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 15) == [0, 2, 4, 6, 8, 10, 12, 14])
    }

    @Test func twentySevenWeeksLabelEverySecondWeekFromTheFirst() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 27) == Array(stride(from: 0, through: 26, by: 2)))
    }

    @Test func twentyEightWeeksStillLabelEverySecondWeek() {
        #expect(ReportWeekAxis.labelledIndices(weekCount: 28) == Array(stride(from: 0, through: 26, by: 2)))
    }

    /// Sunday 15 November 2026: three months back is Saturday 15 August, in the week that starts Sunday 9 August, so
    /// both the first and the last axis week are partial.
    @Test func aThreeMonthPeriodOfFifteenWeeksLabelsEverySecondWeek() throws {
        let now = try #require(american.date(from: DateComponents(year: 2026, month: 11, day: 15, hour: 10)))
        let figures = ReportWeeklyFigures(entries: [], period: .threeMonths, now: now, calendar: american)

        #expect(figures.weekStarts.count == 15)
        #expect(ReportWeekAxis.labelledIndices(weekCount: figures.weekStarts.count) == [0, 2, 4, 6, 8, 10, 12, 14])
    }

    @Test func aDayFirstLocaleLabelsTheDayThenTheShortMonth() throws {
        let monday = try #require(british.date(from: DateComponents(year: 2026, month: 8, day: 10)))
        #expect(ReportWeekAxis.label(for: monday, locale: Locale(identifier: "en_GB"), calendar: british) == "10 Aug")
    }

    @Test func aMonthFirstLocaleLabelsTheShortMonthThenTheDay() throws {
        let sunday = try #require(american.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        #expect(ReportWeekAxis.label(for: sunday, locale: Locale(identifier: "en_US"), calendar: american) == "Aug 9")
    }

    @Test func theLabelIsTheDayInTheCalendarsTimeZone() throws {
        var farEast = british
        farEast.timeZone = TimeZone(identifier: "Pacific/Kiritimati") ?? .gmt
        let midnight = try #require(farEast.date(from: DateComponents(year: 2026, month: 11, day: 9)))
        #expect(ReportWeekAxis.label(for: midnight, locale: Locale(identifier: "en_GB"), calendar: farEast) == "9 Nov")
    }
}
