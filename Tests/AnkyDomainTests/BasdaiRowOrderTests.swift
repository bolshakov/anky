// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyDomain
import Foundation
import Testing

@MainActor
struct BasdaiRowOrderTests {
    private let calendar: Calendar
    private let now: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
    }

    private func at(_ hour: Int, _ minute: Int = 0, _ second: Int = 0, day: Int = 28) throws -> Date {
        let parts = DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute, second: second)
        return try #require(calendar.date(from: parts))
    }

    private func entry(at moment: Date) throws -> Entry {
        try Entry(draft: EntryDraft(severity: #require(Severity(4)), date: moment))
    }

    private func dose(at moment: Date) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: moment)
    }

    private func result(at moment: Date) throws -> BasdaiResult {
        try #require(BasdaiResult(id: UUID(), date: moment, answers: [3, 3, 3, 3, 3, 3]))
    }

    private func today(
        _ entries: [Entry] = [], _ doses: [Dose] = [], _ results: [BasdaiResult] = []
    ) throws -> [UUID] {
        TodayList.items(entries: entries, doses: doses, basdai: results, on: now, calendar: calendar).map(\.id)
    }

    private func history(
        _ entries: [Entry] = [], _ doses: [Dose] = [], _ results: [BasdaiResult] = []
    ) -> [DaySection] {
        HistoryList.sections(entries, doses: doses, basdai: results, now: now, calendar: calendar)
    }

    @Test func aResultCarriesItsIdAndDateAndIsNotADose() throws {
        let saved = try result(at: at(9, 30))
        let item = LoggedItem.basdai(saved)
        #expect(item.id == saved.id)
        #expect(item.date == saved.date)
        #expect(!item.isDose)
    }

    @Test func inOneMinuteADoseComesBeforeAnEntryAndAnEntryBeforeAResult() throws {
        let saved = try result(at: at(9, 30, 50))
        let reading = try entry(at: at(9, 30, 20))
        let taken = try dose(at: at(9, 30, 5))
        #expect(try today([reading], [taken], [saved]) == [taken.id, reading.id, saved.id])
        #expect(history([reading], [taken], [saved]).first?.items.map(\.id) == [taken.id, reading.id, saved.id])
    }

    @Test func theOrderInAMinuteHoldsWhateverTheSaveOrderOfTheKinds() throws {
        let saved = try result(at: at(9, 30, 5))
        let reading = try entry(at: at(9, 30, 50))
        let taken = try dose(at: at(9, 30, 20))
        #expect(try today([reading], [taken], [saved]) == [taken.id, reading.id, saved.id])
    }

    @Test func twoResultsInOneMinuteListTheLaterDateFirstAndBothShowWithTheSameTime() throws {
        let earlier = try result(at: at(9, 30, 10))
        let later = try result(at: at(9, 30, 40))
        #expect(try today([], [], [earlier, later]) == [later.id, earlier.id])
        #expect(try today([], [], [later, earlier]) == [later.id, earlier.id])
        let section = try #require(history([], [], [earlier, later]).first)
        #expect(section.items.map(\.id) == [later.id, earlier.id])
        #expect(ClockText.text(for: earlier.date, calendar: calendar, locale: Locale(identifier: "en_US_POSIX"))
            == ClockText.text(for: later.date, calendar: calendar, locale: Locale(identifier: "en_US_POSIX")))
    }

    @Test func twoResultsOfOneInstantListTheLaterPositionFirst() throws {
        let first = try result(at: at(9, 30, 10))
        let second = try result(at: at(9, 30, 10))
        #expect(try today([], [], [first, second]) == [second.id, first.id])
    }

    @Test func newerMinutesComeFirstWhateverTheKind() throws {
        let newestResult = try result(at: at(9, 32))
        let middleEntry = try entry(at: at(9, 31))
        let oldestDose = try dose(at: at(9, 30))
        let listed = try today([middleEntry], [oldestDose], [newestResult])
        #expect(listed == [newestResult.id, middleEntry.id, oldestDose.id])
    }

    @Test func todayListsOnlyTheResultsOfThatDay() throws {
        let yesterday = try result(at: at(20, day: 27))
        let todays = try result(at: at(8))
        #expect(try today([], [], [yesterday, todays]) == [todays.id])
    }

    @Test func aDayWithOnlyResultsHasASectionAmongTheOthers() throws {
        let onlyResults = try result(at: at(9, day: 25))
        let reading = try entry(at: at(9))
        let result = history([reading], [], [onlyResults])
        #expect(try result.map(\.header) == [.today, .date(at(0, day: 25), includesYear: false)])
        #expect(result.last?.items.map(\.id) == [onlyResults.id])
    }
}
