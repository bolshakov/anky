// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ScheduleValueTests {
    @Test func dayTheGregorianCalendarLacksIsRefused() {
        #expect(ScheduleDay(year: 2026, month: 2, day: 30) == nil)
        #expect(ScheduleDay(year: 2027, month: 2, day: 29) == nil)
        #expect(ScheduleDay(year: 2026, month: 13, day: 1) == nil)
        #expect(ScheduleDay(year: 2026, month: 4, day: 0) == nil)
        #expect(ScheduleDay(year: 2028, month: 2, day: 29) != nil)
    }

    @Test func dayHoldsTheGregorianDateOfAMomentInThatZone() throws {
        let berlin = try #require(TimeZone(identifier: "Europe/Berlin"))
        let auckland = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let moment = Date(timeIntervalSince1970: 1_774_740_000)

        #expect(ScheduleDay(moment, in: berlin) == ScheduleDay(year: 2026, month: 3, day: 29))
        #expect(ScheduleDay(moment, in: auckland) == ScheduleDay(year: 2026, month: 3, day: 29))
        #expect(ScheduleDay(moment.addingTimeInterval(-7200), in: berlin) == ScheduleDay(year: 2026, month: 3, day: 28))
    }

    @Test(arguments: [(-1, 0), (24, 0), (0, 60), (0, -1)])
    func timeOutsideTheClockIsRefused(_ hour: Int, _ minute: Int) {
        #expect(DoseTime(hour: hour, minute: minute) == nil)
    }

    @Test func timesOrderByHourThenMinute() throws {
        let early = try #require(DoseTime(hour: 8, minute: 45))
        let late = try #require(DoseTime(hour: 9, minute: 5))
        let lateTonight = try #require(DoseTime(hour: 9, minute: 30))

        #expect(early < late)
        #expect(late < lateTonight)
    }

    private func build(_ repetition: ScheduleRepeat, times: [DoseTime]? = nil) throws -> MedicationSchedule {
        let clock = try times ?? [#require(DoseTime(hour: 9, minute: 0))]
        let start = try #require(ScheduleDay(year: 2026, month: 3, day: 1))
        return try MedicationSchedule(repeat: repetition, times: clock, start: start, end: nil)
    }

    @Test(arguments: [ScheduleRepeat.days(0), .days(-3), .weeks(0, on: [.monday]), .months(0, onDay: 5)])
    func intervalBelowOneCannotBeBuilt(_ repetition: ScheduleRepeat) {
        #expect(throws: ScheduleError.noInterval) { try build(repetition) }
    }

    @Test func weeksWithNoWeekdayCannotBeBuilt() {
        #expect(throws: ScheduleError.noWeekday) { try build(.weeks(1, on: [])) }
    }

    @Test(arguments: [0, 32, -1]) func dayOfTheMonthOutsideOneToThirtyOneCannotBeBuilt(_ day: Int) {
        #expect(throws: ScheduleError.noSuchDay) { try build(.months(1, onDay: day)) }
    }

    @Test func emptyTimeListCannotBeBuilt() {
        #expect(throws: ScheduleError.noTime) { try build(.days(1), times: []) }
    }

    @Test func everyRepeatThatIsValidIsBuilt() throws {
        let time = try #require(DoseTime(hour: 9, minute: 0))
        let start = try #require(ScheduleDay(year: 2026, month: 3, day: 1))

        for repetition in [ScheduleRepeat.days(1), .weeks(2, on: [.monday, .friday]), .months(1, onDay: 31)] {
            let schedule = try MedicationSchedule(repeat: repetition, times: [time], start: start, end: nil)
            #expect(schedule.repeat == repetition)
        }
    }

    @Test func timesAreSortedAndDuplicatesFoldIntoOne() throws {
        let morning = try #require(DoseTime(hour: 8, minute: 0))
        let evening = try #require(DoseTime(hour: 20, minute: 30))
        let start = try #require(ScheduleDay(year: 2026, month: 3, day: 1))

        let schedule = try MedicationSchedule(
            repeat: .days(1),
            times: [evening, morning, evening, morning],
            start: start,
            end: nil
        )

        #expect(schedule.times == [morning, evening])
    }
}
