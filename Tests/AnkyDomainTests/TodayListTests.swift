import AnkyDomain
import Foundation
import Testing

struct TodayListTests {
    private let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
    }

    private func moment(_ hour: Int, _ minute: Int = 0, _ second: Int = 0, day: Int = 26) throws -> Date {
        let parts = DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute, second: second)
        return try #require(calendar.date(from: parts))
    }

    private func entry(at date: Date) throws -> Entry {
        Entry(draft: EntryDraft(severity: try #require(Severity(4)), date: date))
    }

    private func listedOnDay26(_ all: [Entry]) throws -> [Entry] {
        TodayList.entries(all, on: try moment(12), calendar: calendar)
    }

    @Test func listsOnlyTheEntriesOnThatDay() throws {
        let yesterday = try entry(at: moment(12, day: 25))
        let today = try entry(at: moment(9))
        let tomorrow = try entry(at: moment(9, day: 27))
        #expect(try listedOnDay26([yesterday, today, tomorrow]).map(\.id) == [today.id])
    }

    @Test func returnsNothingWhenNoEntryIsOnThatDay() throws {
        #expect(try listedOnDay26([entry(at: moment(9, day: 25))]).isEmpty)
    }

    @Test func countsTheDayInTheGivenCalendar() throws {
        let justBeforeMidnight = try entry(at: moment(23, 59, 59, day: 25))
        let midnight = try entry(at: moment(0))
        let lastSecond = try entry(at: moment(23, 59, 59))
        let firstSecondOfNext = try entry(at: moment(0, 0, 0, day: 27))
        let all = [justBeforeMidnight, midnight, lastSecond, firstSecondOfNext]
        #expect(try listedOnDay26(all).map(\.id) == [lastSecond.id, midnight.id])
    }

    @Test func ordersByDateNotBySaveOrder() throws {
        let morning = try entry(at: moment(8))
        let evening = try entry(at: moment(20))
        let lunch = try entry(at: moment(13))
        let result = try listedOnDay26([morning, evening, lunch])
        #expect(result.map(\.id) == [evening.id, lunch.id, morning.id])
    }

    @Test func listsTheLaterSavedFirstWhenDatesMatch() throws {
        let date = try moment(9)
        let firstSaved = try entry(at: date)
        let secondSaved = try entry(at: date)
        let result = try listedOnDay26([firstSaved, secondSaved])
        #expect(result.map(\.id) == [secondSaved.id, firstSaved.id])
    }
}
