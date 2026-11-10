// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct NextDosesOnWeekAndMonthRepeatsTests {
    private let berlin: Calendar
    private let auckland: Calendar

    init() throws {
        berlin = try Self.gregorian(in: "Europe/Berlin", firstWeekday: 2)
        auckland = try Self.gregorian(in: "Pacific/Auckland", firstWeekday: 2)
    }

    private static func gregorian(in zone: String, firstWeekday: Int) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func moment(
        _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in calendar: Calendar? = nil, year: Int = 2026
    ) throws -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return try #require((calendar ?? berlin).date(from: parts))
    }

    private func schedule(
        _ repetition: ScheduleRepeat,
        at clock: [(Int, Int)] = [(9, 0)],
        from start: ScheduleDay? = nil,
        to end: ScheduleDay? = nil
    ) throws -> MedicationSchedule {
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let first = try start ?? day(2026, 3, 10)
        return try MedicationSchedule(repeat: repetition, times: times, start: first, end: end)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> ScheduleDay {
        try #require(ScheduleDay(year: year, month: month, day: day))
    }

    // MARK: Weeks

    @Test func everyWeekGivesTheChosenWeekdaysInOrder() throws {
        let doses = try schedule(.weeks(1, on: [.friday, .monday]), at: [(8, 0), (20, 0)])
            .nextDoses(after: moment(3, 16, 9), count: 4, calendar: berlin)

        #expect(try doses == [moment(3, 16, 20), moment(3, 20, 8), moment(3, 20, 20), moment(3, 23, 8)])
    }

    @Test func weekdaysOfTheStartWeekBeforeTheStartDayGiveNoDose() throws {
        let doses = try schedule(.weeks(1, on: [.monday, .friday]))
            .nextDoses(after: moment(3, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 13, 9), moment(3, 16, 9), moment(3, 20, 9)])
    }

    @Test func everyTwoWeeksSkipsTheWeekInBetween() throws {
        let doses = try schedule(.weeks(2, on: [.monday]))
            .nextDoses(after: moment(3, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 23, 9), moment(4, 6, 9), moment(4, 20, 9)])
    }

    @Test func everyFourWeeksSkipsThreeWeeks() throws {
        let doses = try schedule(.weeks(4, on: [.friday]))
            .nextDoses(after: moment(3, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 13, 9), moment(4, 10, 9), moment(5, 8, 9)])
    }

    @Test func theStartWeekDependsOnTheCalendarsFirstWeekday() throws {
        let sunday = try Self.gregorian(in: "Europe/Berlin", firstWeekday: 1)
        let repetition = ScheduleRepeat.weeks(2, on: [.sunday, .monday])
        let wednesdayStart = try day(2026, 3, 11)
        let asked = try moment(3, 10)

        let mondayFirst = try schedule(repetition, from: wednesdayStart)
            .nextDoses(after: asked, count: 4, calendar: berlin)
        let sundayFirst = try schedule(repetition, from: wednesdayStart)
            .nextDoses(after: asked, count: 4, calendar: sunday)

        #expect(try mondayFirst == [moment(3, 15, 9), moment(3, 23, 9), moment(3, 29, 9), moment(4, 6, 9)])
        #expect(try sundayFirst == [moment(3, 22, 9), moment(3, 23, 9), moment(4, 5, 9), moment(4, 6, 9)])
    }

    @Test func askingFarAfterTheStartKeepsTheEveryOtherWeekRhythm() throws {
        let doses = try schedule(.weeks(2, on: [.monday]))
            .nextDoses(after: moment(6, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(6, 1, 9), moment(6, 15, 9), moment(6, 29, 9)])
    }

    @Test func askingInsideASkippedWeekGivesTheNextDoseWeek() throws {
        let doses = try schedule(.weeks(2, on: [.monday, .friday]))
            .nextDoses(after: moment(5, 27), count: 2, calendar: berlin)

        #expect(try doses == [moment(6, 1, 9), moment(6, 5, 9)])
    }

    @Test func aWeeklyScheduleStopsAfterTheEndDaysOwnDoses() throws {
        let doses = try schedule(.weeks(1, on: [.monday, .friday]), to: day(2026, 3, 16))
            .nextDoses(after: moment(3, 1), count: 10, calendar: berlin)

        #expect(try doses == [moment(3, 13, 9), moment(3, 16, 9)])
    }

    @Test func aWeeklyDoseKeepsItsWallClockTimeInAnotherTimeZone() throws {
        let weekly = try schedule(.weeks(1, on: [.thursday]))
        let inBerlin = try weekly.nextDoses(after: moment(3, 10), count: 1, calendar: berlin)
        let inAuckland = try weekly.nextDoses(after: moment(3, 10, in: auckland), count: 1, calendar: auckland)

        #expect(try inBerlin == [moment(3, 12, 9)])
        #expect(try inAuckland == [moment(3, 12, 9, in: auckland)])
    }

    @Test func aSkippedDaylightSavingTimeLandsAtTheEndOfTheGapOnAWeeklyRepeat() throws {
        let doses = try schedule(.weeks(1, on: [.sunday]), at: [(2, 30)], from: day(2026, 3, 22))
            .nextDoses(after: moment(3, 22, 12), count: 2, calendar: berlin)

        #expect(try doses == [moment(3, 29, 3, 0), moment(4, 5, 2, 30)])
    }

    @Test func aRepeatedDaylightSavingTimeUsesTheFirstMomentOnAWeeklyRepeat() throws {
        let doses = try schedule(.weeks(1, on: [.sunday]), at: [(2, 30)], from: day(2026, 10, 18))
            .nextDoses(after: moment(10, 18, 12), count: 1, calendar: berlin)

        #expect(try doses == [firstTwoThirtyOnTheDaylightSavingEnd()])
    }

    // MARK: Months

    @Test func everyMonthGivesTheChosenDayOfEachMonth() throws {
        let doses = try schedule(.months(1, onDay: 12), at: [(8, 0), (20, 0)])
            .nextDoses(after: moment(3, 1), count: 4, calendar: berlin)

        #expect(try doses == [moment(3, 12, 8), moment(3, 12, 20), moment(4, 12, 8), moment(4, 12, 20)])
    }

    @Test func aDayOfTheMonthBeforeTheStartDayWaitsForTheNextMonth() throws {
        let doses = try schedule(.months(1, onDay: 5))
            .nextDoses(after: moment(3, 1), count: 2, calendar: berlin)

        #expect(try doses == [moment(4, 5, 9), moment(5, 5, 9)])
    }

    @Test func everyThreeMonthsCountsFromTheStartMonth() throws {
        let doses = try schedule(.months(3, onDay: 15))
            .nextDoses(after: moment(3, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 15, 9), moment(6, 15, 9), moment(9, 15, 9)])
    }

    @Test func askingFarAfterTheStartKeepsTheMonthRhythm() throws {
        let doses = try schedule(.months(5, onDay: 12))
            .nextDoses(after: moment(1, 1, year: 2028), count: 2, calendar: berlin)

        #expect(try doses == [moment(4, 12, 9, year: 2028), moment(9, 12, 9, year: 2028)])
    }

    @Test func aShortMonthUsesItsLastDayAndTheNextMonthGoesBackToTheDay() throws {
        let doses = try schedule(.months(1, onDay: 31), from: day(2027, 1, 1))
            .nextDoses(after: moment(1, 1, year: 2027), count: 5, calendar: berlin)

        #expect(try doses == [(1, 31), (2, 28), (3, 31), (4, 30), (5, 31)].map { try moment($0, $1, 9, year: 2027) })
    }

    @Test func everyTwoMonthsOnDay31LandsOnThe30thOfApril() throws {
        let doses = try schedule(.months(2, onDay: 31), from: day(2026, 12, 31))
            .nextDoses(after: moment(12, 1), count: 4, calendar: berlin)

        #expect(try doses == [moment(12, 31, 9)] + [(2, 28), (4, 30), (6, 30)]
            .map { try moment($0, $1, 9, year: 2027) })
    }

    @Test(arguments: [29, 30, 31], [(year: 2027, last: 28), (year: 2028, last: 29), (year: 2100, last: 28)])
    func aDayOf29To31LandsInFebruaryOnItsLastDay(monthDay: Int, february: (year: Int, last: Int)) throws {
        let doses = try schedule(.months(1, onDay: monthDay), from: day(february.year, 2, 1))
            .nextDoses(after: moment(2, 1, year: february.year), count: 1, calendar: berlin)

        #expect(try doses == [moment(2, february.last, 9, year: february.year)])
    }

    @Test func aMonthlyScheduleStopsAfterTheEndDaysOwnDoses() throws {
        let doses = try schedule(.months(1, onDay: 12), to: day(2026, 5, 12))
            .nextDoses(after: moment(3, 1), count: 10, calendar: berlin)

        #expect(try doses == [moment(3, 12, 9), moment(4, 12, 9), moment(5, 12, 9)])
    }

    @Test func aClampedDayCountsAsTheEndDay() throws {
        let doses = try schedule(.months(1, onDay: 31), from: day(2027, 1, 1), to: day(2027, 2, 28))
            .nextDoses(after: moment(1, 1, year: 2027), count: 10, calendar: berlin)

        #expect(try doses == [moment(1, 31, 9, year: 2027), moment(2, 28, 9, year: 2027)])
    }

    @Test func aMonthlyDoseKeepsItsWallClockTimeInAnotherTimeZone() throws {
        let monthly = try schedule(.months(1, onDay: 12))
        let inBerlin = try monthly.nextDoses(after: moment(3, 1), count: 1, calendar: berlin)
        let inAuckland = try monthly.nextDoses(after: moment(3, 1, in: auckland), count: 1, calendar: auckland)

        #expect(try inBerlin == [moment(3, 12, 9)])
        #expect(try inAuckland == [moment(3, 12, 9, in: auckland)])
    }

    @Test func aCalendarWithOtherMonthsGivesTheSameMonthlyDoses() throws {
        var islamic = Calendar(identifier: .islamicCivil)
        islamic.timeZone = berlin.timeZone

        let doses = try schedule(.months(1, onDay: 31), from: day(2027, 1, 1))
            .nextDoses(after: moment(1, 1, year: 2027), count: 3, calendar: islamic)

        #expect(try doses == [(1, 31), (2, 28), (3, 31)].map { try moment($0, $1, 9, year: 2027) })
    }

    @Test func aSkippedDaylightSavingTimeLandsAtTheEndOfTheGapOnAMonthlyRepeat() throws {
        let doses = try schedule(.months(1, onDay: 29), at: [(2, 30)], from: day(2026, 2, 1))
            .nextDoses(after: moment(3, 1), count: 2, calendar: berlin)

        #expect(try doses == [moment(3, 29, 3, 0), moment(4, 29, 2, 30)])
    }

    @Test func aRepeatedDaylightSavingTimeUsesTheFirstMomentOnAMonthlyRepeat() throws {
        let doses = try schedule(.months(1, onDay: 25), at: [(2, 30)], from: day(2026, 10, 1))
            .nextDoses(after: moment(10, 1), count: 1, calendar: berlin)

        #expect(try doses == [firstTwoThirtyOnTheDaylightSavingEnd()])
    }

    private func firstTwoThirtyOnTheDaylightSavingEnd() throws -> Date {
        try #require(ISO8601DateFormatter().date(from: "2026-10-25T02:30:00+02:00"))
    }
}
