// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DailyReminderTimePickerTests {
    private func calendar(_ zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    private func clock(of date: Date, in calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.hour, .minute], from: date)
    }

    @Test(arguments: ["UTC", "Europe/Moscow", "America/New_York"])
    func theTimeBecomesADateThatReadsTheSameClockInTheCalendar(zone: String) throws {
        let calendar = try calendar(zone)
        let date = DailyReminderTime(hour: 20, minute: 5).date(
            on: Date(timeIntervalSince1970: 1_900_000_000),
            calendar: calendar
        )
        let parts = clock(of: date, in: calendar)
        #expect(parts.hour == 20)
        #expect(parts.minute == 5)
    }

    @Test(arguments: ["UTC", "Europe/Moscow", "America/New_York"])
    func aDateBecomesTheTimeItReadsInTheCalendar(zone: String) throws {
        let calendar = try calendar(zone)
        let date = try #require(calendar.date(from: DateComponents(year: 2030, month: 3, day: 10, hour: 7, minute: 45)))
        #expect(DailyReminderTime(date: date, calendar: calendar) == DailyReminderTime(hour: 7, minute: 45))
    }

    @Test func midnightAndTheLastMinuteRoundTrip() throws {
        let calendar = try calendar("UTC")
        let day = Date(timeIntervalSince1970: 1_900_000_000)
        for time in [DailyReminderTime(hour: 0, minute: 0), DailyReminderTime(hour: 23, minute: 59)] {
            #expect(DailyReminderTime(date: time.date(on: day, calendar: calendar), calendar: calendar) == time)
        }
    }
}
