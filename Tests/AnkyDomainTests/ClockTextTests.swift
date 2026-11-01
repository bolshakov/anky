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

    @Test func theBritishClockReadsTwoDigitsOnA24HourClockInTheCalendarsZone() throws {
        // 00:30 in Auckland is 12:30 in Berlin, so a formatter that ignored the calendar's zone would fail here.
        #expect(try clock("en_GB", hour: 0, minute: 30) == "00:30")
    }

    @Test func theUnitedStatesClockReadsTheHourWithoutAZeroAndAnAmPmSuffix() throws {
        #expect(try clock("en_US", hour: 8, minute: 15) == "8:15\u{202F}AM")
        #expect(try clock("en_US", hour: 13, minute: 5) == "1:05\u{202F}PM")
    }
}
