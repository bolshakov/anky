import AnkyDomain
import Foundation
import Testing

struct BackdatedEntryTests {
    private let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
    }

    private func moment(day: Int, hour: Int, minute: Int) throws -> Date {
        let parts = DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)
        return try #require(calendar.date(from: parts))
    }

    @Test func entryBackdatedAcrossMidnightIsSavedButNotListedOnToday() throws {
        let now = try moment(day: 26, hour: 0, minute: 30)
        let lateYesterday = try moment(day: 25, hour: 23, minute: 30)
        let backdated = try Entry(draft: EntryDraft(severity: #require(Severity(4)), date: lateYesterday))
        let store = FakeEntryStore()
        var log = EntryLog(store: store)

        try log.add(backdated)

        #expect(store.saved == [backdated])
        #expect(TodayList.entries(log.entries, on: now, calendar: calendar).isEmpty)
    }
}
