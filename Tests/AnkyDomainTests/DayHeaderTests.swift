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

    @Test func anOlderDateHeaderHasTheLongWeekdayDayAndMonth() throws {
        let header = try header(day: 24)
        let start = try dayStart(day: 24)
        #expect(header == .date(start, includesYear: false))
        let text = try dateText(of: header, us)
        #expect(text.contains("Saturday"))
        #expect(text.contains("24"))
        #expect(text.contains("October"))
        #expect(!text.contains("2026"))
    }

    @Test func aDateHeaderFollowsThePhonesOrderAndLanguage() throws {
        let header = try header(day: 24)
        let usText = try dateText(of: header, us)
        let gbText = try dateText(of: header, Locale(identifier: "en_GB"))
        let frText = try dateText(of: header, Locale(identifier: "fr_FR"))
        #expect(try precedes("October", "24", in: usText))
        #expect(try precedes("24", "October", in: gbText))
        #expect(frText.contains("samedi"))
        #expect(frText.contains("octobre"))
    }

    @Test func aSameYearDateReadsLikeTheTodaySubtitle() throws {
        let header = try header(day: 24)
        let start = try dayStart(day: 24)
        let subtitle = Date.FormatStyle(locale: us, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide)
        #expect(try dateText(of: header, us) == start.formatted(subtitle))
    }

    @Test func aDateInAnotherYearIncludesTheYear() throws {
        let header = try header(year: 2025, month: 12, day: 31)
        #expect(try header == .date(dayStart(year: 2025, month: 12, day: 31), includesYear: true))
        #expect(try dateText(of: header, us).contains("2025"))
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
