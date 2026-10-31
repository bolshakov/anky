// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DayDateTextTests {
    private let calendar: Calendar
    private let day: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        day = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12)))
    }

    private func text(_ identifier: String, includesYear: Bool = false) -> String {
        DayDateText.text(for: day, includesYear: includesYear, calendar: calendar,
                         locale: Locale(identifier: identifier))
    }

    private func plain(_ identifier: String, includesYear: Bool = false) -> String {
        var style = Date.FormatStyle(locale: Locale(identifier: identifier), calendar: calendar,
                                     timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide)
        if includesYear {
            style = style.year()
        }
        return day.formatted(style)
    }

    @Test func englishWeekdayIsCapitalisedAndTheRestIsLowercase() {
        #expect(text("en_US") == "Saturday, October 24")
        #expect(text("en_GB") == "Saturday 24 October")
    }

    @Test func russianWeekdayIsCapitalisedAndTheMonthKeepsItsCase() {
        #expect(text("ru_RU") == "Суббота, 24 октября")
    }

    @Test(arguments: [
        ("en_US", "Saturday", "Saturday"),
        ("en_GB", "Saturday", "Saturday"),
        ("en_DE", "Saturday", "Saturday"),
        ("ru_RU", "суббота", "Суббота")
    ])
    func onlyTheWeekdayChanges(identifier: String, lowercase: String, capitalised: String) {
        #expect(text(identifier) == plain(identifier).replacingOccurrences(of: lowercase, with: capitalised))
    }

    @Test(arguments: [
        ("en_US", "Saturday", "Saturday"),
        ("ru_RU", "суббота", "Суббота")
    ])
    func onlyTheWeekdayChangesInTheYearForm(identifier: String, lowercase: String, capitalised: String) {
        let expected = plain(identifier, includesYear: true).replacingOccurrences(of: lowercase, with: capitalised)
        #expect(text(identifier, includesYear: true) == expected)
    }
}
