// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DailyReminderTests {
    private func calendar(_ zone: String = "UTC") throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    private func moment(_ day: Int, _ hour: Int, _ minute: Int = 0, in calendar: Calendar) throws -> Date {
        let parts = DateComponents(year: 2030, month: 3, day: day, hour: hour, minute: minute)
        return try #require(calendar.date(from: parts))
    }

    private func entry(at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(4)), date: date, note: nil, places: [])
    }

    private func dose(at date: Date) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: date)
    }

    private let evening = DailyReminderTime(hour: 20, minute: 0)

    @Test func theStandardTimeIsEightInTheEvening() {
        #expect(DailyReminderTime.standard == DailyReminderTime(hour: 20, minute: 0))
    }

    @Test func theIdentifierIsFixedAndNotAUUID() {
        #expect(DailyReminder.identifier == "daily-reminder")
        #expect(UUID(uuidString: DailyReminder.identifier) == nil)
    }

    @Test func withNothingLoggedAndTheTimeAheadTodayTheReminderIsToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [], doses: [], time: evening, now: moment(10, 9, in: calendar), calendar: calendar
        )
        #expect(try fire == moment(10, 20, in: calendar))
    }

    @Test func withTheTimeAlreadyPassedTodayTheReminderIsTomorrowAtThatTime() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [], doses: [], time: evening, now: moment(10, 21, in: calendar), calendar: calendar
        )
        #expect(try fire == moment(11, 20, in: calendar))
    }

    @Test func atTheExactTimeTheReminderIsTomorrowBecauseItMustBeAfterNow() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [], doses: [], time: evening, now: moment(10, 20, in: calendar), calendar: calendar
        )
        #expect(try fire == moment(11, 20, in: calendar))
    }

    @Test func aMinuteInTheTimeIsKept() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [],
            doses: [],
            time: DailyReminderTime(hour: 7, minute: 45),
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(11, 7, 45, in: calendar))
    }

    @Test func anEntryDatedTodaySkipsToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [entry(at: moment(10, 8, in: calendar))],
            doses: [],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(11, 20, in: calendar))
    }

    @Test func anEntryDatedLaterTodayThanNowStillSkipsToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [entry(at: moment(10, 23, 59, in: calendar))],
            doses: [],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(11, 20, in: calendar))
    }

    @Test func anEntryBackdatedToAnotherDayDoesNotSkipToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [entry(at: moment(9, 23, 59, in: calendar))],
            doses: [],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(10, 20, in: calendar))
    }

    @Test func aDoseTakenTodaySkipsToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [],
            doses: [dose(at: moment(10, 7, in: calendar))],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(11, 20, in: calendar))
    }

    @Test func aDoseTakenOnAnotherDayDoesNotSkipToday() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [],
            doses: [dose(at: moment(9, 7, in: calendar))],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(10, 20, in: calendar))
    }

    @Test func theReminderMovesToTomorrowOnceTodayIsLoggedAfterItWasSetForToday() throws {
        let calendar = try calendar()
        let now = try moment(10, 9, in: calendar)
        let before = try DailyReminder.fireDate(entries: [], doses: [], time: evening, now: now, calendar: calendar)
        let after = try DailyReminder.fireDate(
            entries: [entry(at: now)], doses: [], time: evening, now: now, calendar: calendar
        )
        #expect(try before == moment(10, 20, in: calendar))
        #expect(try after == moment(11, 20, in: calendar))
    }

    @Test func daysWithAnEntryOrADoseAreAllSkippedToTheFirstEmptyDay() throws {
        let calendar = try calendar()
        let fire = try DailyReminder.fireDate(
            entries: [entry(at: moment(10, 8, in: calendar)), entry(at: moment(12, 8, in: calendar))],
            doses: [dose(at: moment(11, 8, in: calendar))],
            time: evening,
            now: moment(10, 9, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(13, 20, in: calendar))
    }

    @Test func aDayIsADayOfThePassedCalendar() throws {
        let berlin = try calendar("Europe/Berlin")
        let utc = try calendar()
        let lateInUTC = try moment(10, 23, 30, in: utc)
        let now = try moment(10, 9, in: berlin)
        let fireInBerlin = try DailyReminder.fireDate(
            entries: [entry(at: lateInUTC)], doses: [], time: evening, now: now, calendar: berlin
        )
        let fireInUTC = try DailyReminder.fireDate(
            entries: [entry(at: lateInUTC)], doses: [], time: evening, now: now, calendar: utc
        )
        #expect(try fireInBerlin == moment(10, 20, in: berlin))
        #expect(try fireInUTC == moment(11, 20, in: utc))
    }

    @Test func theTimeIsKeptOnTheClockAcrossAClockChange() throws {
        let calendar = try calendar("America/New_York")
        let fire = try DailyReminder.fireDate(
            entries: [],
            doses: [],
            time: evening,
            now: moment(9, 21, in: calendar),
            calendar: calendar
        )
        #expect(try fire == moment(10, 20, in: calendar))
    }

    @Test func aWeekOfLoggedDaysStillFindsTheDayAfterThem() throws {
        let calendar = try calendar()
        let entries = try (10 ... 16).map { try entry(at: moment($0, 8, in: calendar)) }
        let fire = try DailyReminder.fireDate(
            entries: entries, doses: [], time: evening, now: moment(10, 9, in: calendar), calendar: calendar
        )
        #expect(try fire == moment(17, 20, in: calendar))
    }

    @Test func whenNoDayIsFreeWithinTheSearchTheResultIsNil() throws {
        let calendar = try calendar()
        let now = try moment(10, 9, in: calendar)
        let entries = try (0 ..< 60).map { try entry(at: now.addingTimeInterval(TimeInterval($0 * 24 * 3600))) }
        let fire = try DailyReminder.fireDate(entries: entries, doses: [], time: evening, now: now, calendar: calendar)
        #expect(fire == nil)
    }
}
