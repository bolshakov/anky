// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct NextDosesOnDayRepeatsTests {
    private let berlin: Calendar
    private let auckland: Calendar

    init() throws {
        berlin = try Self.gregorian(in: "Europe/Berlin")
        auckland = try Self.gregorian(in: "Pacific/Auckland")
    }

    private static func gregorian(in zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    private func moment(
        _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in calendar: Calendar? = nil, year: Int = 2026
    ) throws -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return try #require((calendar ?? berlin).date(from: parts))
    }

    private func schedule(
        _ repetition: ScheduleRepeat = .days(1),
        at clock: [(Int, Int)] = [(9, 0)],
        from start: (Int, Int) = (3, 10),
        to end: (Int, Int)? = nil
    ) throws -> MedicationSchedule {
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let first = try #require(ScheduleDay(year: 2026, month: start.0, day: start.1))
        let last = try end.map { try #require(ScheduleDay(year: 2026, month: $0.0, day: $0.1)) }
        return try MedicationSchedule(repeat: repetition, times: times, start: first, end: last)
    }

    @Test func everyDayGivesTheNextDosesInOrder() throws {
        let doses = try schedule(at: [(8, 0), (20, 0)])
            .nextDoses(after: moment(3, 12, 8, 30), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 12, 20), moment(3, 13, 8), moment(3, 13, 20)])
    }

    @Test func everyThirdDayCountsFromTheStartDay() throws {
        let doses = try schedule(.days(3)).nextDoses(after: moment(6, 1), count: 3, calendar: berlin)

        #expect(try doses == [moment(6, 2, 9), moment(6, 5, 9), moment(6, 8, 9)])
    }

    @Test func askingAfterAMomentThatIsExactlyADoseGivesTheNextDose() throws {
        let doses = try schedule().nextDoses(after: moment(3, 12, 9), count: 2, calendar: berlin)

        #expect(try doses == [moment(3, 13, 9), moment(3, 14, 9)])
    }

    @Test func askingBeforeTheStartDayGivesTheFirstDosesOnOrAfterIt() throws {
        let doses = try schedule(at: [(8, 0), (20, 0)])
            .nextDoses(after: moment(1, 5), count: 3, calendar: berlin)

        #expect(try doses == [moment(3, 10, 8), moment(3, 10, 20), moment(3, 11, 8)])
    }

    @Test func endDaysOwnDosesCountAndNoDoseFollows() throws {
        let doses = try schedule(at: [(8, 0), (20, 0)], to: (3, 11))
            .nextDoses(after: moment(3, 10, 12), count: 10, calendar: berlin)

        #expect(try doses == [moment(3, 10, 20), moment(3, 11, 8), moment(3, 11, 20)])
    }

    @Test func nothingIsGivenAfterTheEndDay() throws {
        let doses = try schedule(to: (3, 11)).nextDoses(after: moment(3, 12), count: 3, calendar: berlin)

        #expect(doses.isEmpty)
    }

    @Test func endDayBeforeTheStartDayBuildsAndGivesNoDoses() throws {
        let backwards = try schedule(from: (3, 10), to: (3, 9))

        #expect(try backwards.nextDoses(after: moment(3, 1), count: 3, calendar: berlin).isEmpty)
    }

    @Test(arguments: [0, -2]) func noCountGivesNoDoses(_ count: Int) throws {
        let doses = try schedule().nextDoses(after: moment(3, 1), count: count, calendar: berlin)

        #expect(doses.isEmpty)
    }

    @Test func weekAndMonthRepeatsGiveNothingYet() throws {
        let weekly = try schedule(.weeks(1, on: [.monday]))
        let monthly = try schedule(.months(1, onDay: 12))

        #expect(try weekly.nextDoses(after: moment(3, 1), count: 3, calendar: berlin).isEmpty)
        #expect(try monthly.nextDoses(after: moment(3, 1), count: 3, calendar: berlin).isEmpty)
    }

    @Test func aDoseKeepsItsWallClockTimeInAnotherTimeZone() throws {
        let daily = try schedule()
        let inBerlin = try daily.nextDoses(after: moment(3, 12), count: 1, calendar: berlin)
        let inAuckland = try daily.nextDoses(after: moment(3, 12, in: auckland), count: 1, calendar: auckland)

        #expect(try inBerlin == [moment(3, 12, 9)])
        #expect(try inAuckland == [moment(3, 12, 9, in: auckland)])
    }

    @Test func aCalendarThatIsNotGregorianGivesTheSameDoses() throws {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = berlin.timeZone

        let doses = try schedule(.days(2)).nextDoses(after: moment(3, 10, 9), count: 2, calendar: buddhist)

        #expect(try doses == [moment(3, 12, 9), moment(3, 14, 9)])
    }

    @Test func aSkippedDaylightSavingTimeLandsAtTheEndOfTheGap() throws {
        let doses = try schedule(at: [(2, 30)], from: (3, 28))
            .nextDoses(after: moment(3, 28, 12), count: 2, calendar: berlin)

        #expect(try doses == [moment(3, 29, 3, 0), moment(3, 30, 2, 30)])
    }

    @Test func aRepeatedDaylightSavingTimeUsesTheFirstMoment() throws {
        let doses = try schedule(at: [(2, 30)], from: (10, 24))
            .nextDoses(after: moment(10, 24, 12), count: 1, calendar: berlin)
        let summerTwoThirty = try #require(ISO8601DateFormatter().date(from: "2026-10-25T02:30:00+02:00"))

        #expect(doses == [summerTwoThirty])
    }
}
