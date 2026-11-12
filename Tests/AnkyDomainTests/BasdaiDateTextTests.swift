// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct BasdaiDateTextTests {
    private let calendar: Calendar
    private let date: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 0, minute: 30)))
    }

    private func text(_ identifier: String) -> String {
        BasdaiDateText.text(for: date, calendar: calendar, locale: Locale(identifier: identifier))
    }

    @Test func englishWritesTheDayMonthNameAndYearWithNoWeekday() {
        #expect(text("en_GB") == "10 November 2026")
        #expect(text("en_US") == "November 10, 2026")
    }

    @Test func russianWritesTheMonthNameInTheGenitiveWithNoWeekday() {
        #expect(text("ru_RU") == "10 ноября 2026\u{202F}г.")
    }
}
