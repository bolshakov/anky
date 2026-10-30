import AnkyDomain
import Foundation
import Testing

struct DayHeaderTests {
    private let calendar: Calendar
    private let now: Date
    private let us = Locale(identifier: "en_US")

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
    }

    private func dayStart(year: Int = 2026, month: Int = 10, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func header(year: Int = 2026, month: Int = 10, day: Int) throws -> DayHeader {
        let moment = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
        let entry = try Entry(draft: EntryDraft(severity: #require(Severity(4)), date: moment))
        return try #require(HistoryList.sections([entry], now: now, calendar: calendar).first?.header)
    }

    private func dateText(of header: DayHeader, _ locale: Locale) throws -> String {
        try #require(header.dateText(calendar: calendar, locale: locale))
    }

    private func precedes(_ first: String, _ second: String, in text: String) throws -> Bool {
        let firstRange = try #require(text.range(of: first))
        let secondRange = try #require(text.range(of: second))
        return firstRange.lowerBound < secondRange.lowerBound
    }

    private func subtitle(of day: Date, _ locale: Locale) -> String {
        day.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide))
    }

    @Test func anOlderDateHeaderHasTheWeekdayInCapitalsAndTheDayAndMonth() throws {
        let header = try header(day: 24)
        let start = try dayStart(day: 24)
        #expect(header == .date(start, includesYear: false))
        let text = try dateText(of: header, us)
        #expect(text.contains("SATURDAY"))
        #expect(text.contains("24"))
        #expect(text.contains("October"))
        #expect(!text.contains("Saturday"))
        #expect(!text.contains("2026"))
    }

    @Test func aDateHeaderFollowsThePhonesOrderAndLanguage() throws {
        let header = try header(day: 24)
        let usText = try dateText(of: header, us)
        let gbText = try dateText(of: header, Locale(identifier: "en_GB"))
        let frText = try dateText(of: header, Locale(identifier: "fr_FR"))
        #expect(try precedes("October", "24", in: usText))
        #expect(try precedes("24", "October", in: gbText))
        #expect(frText.contains("SAMEDI"))
        #expect(frText.contains("octobre"))
    }

    @Test func aSameYearDateReadsLikeTheTodaySubtitleWithTheWeekdayInCapitals() throws {
        let header = try header(day: 24)
        let start = try dayStart(day: 24)
        let expected = subtitle(of: start, us).replacingOccurrences(of: "Saturday", with: "SATURDAY")
        #expect(try dateText(of: header, us) == expected)
    }

    @Test func aDateInAnotherYearIncludesTheYear() throws {
        let header = try header(year: 2025, month: 12, day: 31)
        #expect(try header == .date(dayStart(year: 2025, month: 12, day: 31), includesYear: true))
        #expect(try dateText(of: header, us).contains("2025"))
    }

    @Test func onlyTheWeekdayIsInCapitals() throws {
        let start = try dayStart(day: 24)
        let header = try header(day: 24)
        for locale in [us, Locale(identifier: "en_GB")] {
            let text = try dateText(of: header, locale).replacingOccurrences(of: "SATURDAY", with: "")
            let plain = subtitle(of: start, locale).replacingOccurrences(of: "Saturday", with: "")
            #expect(text == plain)
        }
    }

    @Test func aRussianWeekdayIsInCapitalsAndTheMonthIsNot() throws {
        let header = try header(day: 24)
        let text = try dateText(of: header, Locale(identifier: "ru_RU"))
        #expect(text.contains("СУББОТА"))
        #expect(text.contains("октября"))
        #expect(!text.contains("Суббота"))
        #expect(!text.contains("суббота"))
        #expect(!text.contains("ОКТЯБРЯ"))
    }

    @Test func theYearFormKeepsOnlyTheWeekdayInCapitals() throws {
        let header = try header(year: 2025, month: 12, day: 31)
        let text = try dateText(of: header, us)
        #expect(text.contains("WEDNESDAY"))
        #expect(text.contains("December"))
        #expect(text.contains("2025"))
        #expect(!text.contains("Wednesday"))
    }

    @Test func aDateInTheSameYearLeavesTheYearOut() throws {
        let header = try header(year: 2026, month: 1, day: 1)
        #expect(try header == .date(dayStart(year: 2026, month: 1, day: 1), includesYear: false))
    }

    @Test func todayAndYesterdayHaveNoDateText() {
        #expect(DayHeader.today.dateText(calendar: calendar, locale: us) == nil)
        #expect(DayHeader.yesterday.dateText(calendar: calendar, locale: us) == nil)
    }
}
