// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ClockTextTests {
    private let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
    }

    private func clock(_ identifier: String, hour: Int, minute: Int) throws -> String {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1,
                                                                   hour: hour, minute: minute)))
        return ClockText.text(for: date, calendar: calendar, locale: Locale(identifier: identifier))
    }

    @Test func theBritishClockWritesTheHourWithoutAZeroOnA24HourClock() throws {
        #expect(try clock("en_GB", hour: 9, minute: 5) == "9:05")
        #expect(try clock("en_GB", hour: 12, minute: 59) == "12:59")
        #expect(try clock("en_GB", hour: 21, minute: 5) == "21:05")
        // 00:30 in Auckland is 12:30 in Berlin, so a formatter that ignored the calendar's zone would fail here.
        #expect(try clock("en_GB", hour: 0, minute: 30) == "0:30")
    }

    @Test func theUnitedStatesClockWritesTheHourWithoutAZeroAndAnAmPmSuffix() throws {
        #expect(try clock("en_US", hour: 9, minute: 5) == "9:05\u{202F}AM")
        #expect(try clock("en_US", hour: 12, minute: 59) == "12:59\u{202F}PM")
        #expect(try clock("en_US", hour: 21, minute: 5) == "9:05\u{202F}PM")
        #expect(try clock("en_US", hour: 0, minute: 30) == "12:30\u{202F}AM")
    }

    @Test func theRussianClockWritesTheHourWithoutAZeroOnA24HourClock() throws {
        #expect(try clock("ru_RU", hour: 9, minute: 5) == "9:05")
        #expect(try clock("ru_RU", hour: 12, minute: 59) == "12:59")
        #expect(try clock("ru_RU", hour: 21, minute: 5) == "21:05")
        #expect(try clock("ru_RU", hour: 0, minute: 30) == "0:30")
    }
}
