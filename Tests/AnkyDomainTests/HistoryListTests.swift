// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct HistoryListTests {
    private let calendar: Calendar
    private let now: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
    }

    private func date(_ parts: DateComponents) throws -> Date {
        try #require(calendar.date(from: parts))
    }

    private func at(_ hour: Int, _ minute: Int = 0, _ second: Int = 0, day: Int = 28) throws -> Date {
        try date(DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute, second: second))
    }

    private func entry(at moment: Date) throws -> Entry {
        try Entry(draft: EntryDraft(severity: #require(Severity(4)), date: moment))
    }

    private func sections(_ all: [Entry], doses: [Dose] = []) -> [DaySection] {
        HistoryList.sections(all, doses: doses, now: now, calendar: calendar)
    }

    @Test func entriesOnThreeDaysMakeThreeSectionsNewestFirst() throws {
        let today = try entry(at: at(9))
        let yesterday = try entry(at: at(20, day: 27))
        let fourDaysAgo = try entry(at: at(8, day: 24))
        let fourDaysAgoStart = try at(0, day: 24)
        let result = sections([fourDaysAgo, today, yesterday])
        #expect(result.map(\.header) == [.today, .yesterday, .date(fourDaysAgoStart, includesYear: false)])
        #expect(result.map { $0.items.map(\.id) } == [[today.id], [yesterday.id], [fourDaysAgo.id]])
    }

    @Test func aDayWithNoEntriesHasNoSection() throws {
        let yesterday = try entry(at: at(9, day: 27))
        let result = sections([yesterday])
        #expect(result.map(\.header) == [.yesterday])
        #expect(result.map { $0.items.map(\.id) } == [[yesterday.id]])
    }

    @Test func aLogWithNoEntriesHasNoSections() {
        #expect(sections([]).isEmpty)
    }

    @Test func theLaterEntryIsFirstInsideADay() throws {
        let lunch = try entry(at: at(13))
        let evening = try entry(at: at(20))
        let morning = try entry(at: at(8))
        let section = try #require(sections([lunch, evening, morning]).first)
        #expect(section.items.map(\.id) == [evening.id, lunch.id, morning.id])
    }

    @Test func entriesInTheSameMinuteListTheLaterSavedFirst() throws {
        let firstSaved = try entry(at: at(9, 30, 45))
        let secondSaved = try entry(at: at(9, 30, 10))
        let section = try #require(sections([firstSaved, secondSaved]).first)
        #expect(section.items.map(\.id) == [secondSaved.id, firstSaved.id])
    }

    private func dose(at moment: Date) throws -> Dose {
        try Dose(id: UUID(), medicationID: UUID(), takenAt: moment, painBefore: #require(Severity(6)))
    }

    @Test func aDoseInTheSameMinuteAsAnEntryListsFirstWhateverTheSeconds() throws {
        let entryLater = try entry(at: at(9, 30, 50))
        let doseEarlier = try dose(at: at(9, 30, 5))
        #expect(sections([entryLater], doses: [doseEarlier]).first?.items.map(\.id) == [doseEarlier.id, entryLater.id])

        let entryEarlier = try entry(at: at(9, 30, 5))
        let doseLater = try dose(at: at(9, 30, 50))
        #expect(sections([entryEarlier], doses: [doseLater]).first?.items.map(\.id) == [doseLater.id, entryEarlier.id])
    }

    @Test func aDoseBeforeTwoEntriesInOneMinuteKeepsTheEntriesInSaveOrder() throws {
        let firstSaved = try entry(at: at(9, 30, 45))
        let secondSaved = try entry(at: at(9, 30, 10))
        let taken = try dose(at: at(9, 30, 30))
        let result = sections([firstSaved, secondSaved], doses: [taken])
        #expect(result.first?.items.map(\.id) == [taken.id, secondSaved.id, firstSaved.id])
    }

    @Test func twoDosesInOneMinuteListTheLaterStoredFirstThenTheLaterPosition() throws {
        let earlyStored = try dose(at: at(9, 30, 10))
        let lateStored = try dose(at: at(9, 30, 40))
        let tieFirst = try dose(at: at(9, 30, 20))
        let tieSecond = try dose(at: at(9, 30, 20))
        let result = sections([], doses: [earlyStored, lateStored, tieFirst, tieSecond])
        #expect(result.first?.items.map(\.id) == [lateStored.id, tieSecond.id, tieFirst.id, earlyStored.id])
    }

    @Test func anEntryAt2359AndOneAt0001FallInDifferentSections() throws {
        let lateYesterday = try entry(at: at(23, 59, day: 27))
        let justAfterMidnight = try entry(at: at(0, 1))
        let result = sections([lateYesterday, justAfterMidnight])
        #expect(result.map(\.header) == [.today, .yesterday])
        #expect(result.map { $0.items.map(\.id) } == [[justAfterMidnight.id], [lateYesterday.id]])
    }

    @Test func theSameInstantFallsOnAnotherDayInAnotherTimeZone() throws {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let later = try entry(at: at(10))
        let earlier = try entry(at: at(22, day: 27))
        let inAuckland = HistoryList.sections([later, earlier], doses: [], now: now, calendar: calendar)
        let inLosAngeles = HistoryList.sections([later, earlier], doses: [], now: now, calendar: losAngeles)
        #expect(inAuckland.map(\.header) == [.today, .yesterday])
        #expect(inAuckland.map { $0.items.map(\.id) } == [[later.id], [earlier.id]])
        #expect(inLosAngeles.map(\.header) == [.today])
        #expect(inLosAngeles.map { $0.items.map(\.id) } == [[later.id, earlier.id]])
    }

    @Test func yesterdayHoldsAcrossAClockChange() throws {
        let afterChange = try date(DateComponents(year: 2026, month: 9, day: 28, hour: 10))
        let beforeChange = try entry(at: date(DateComponents(year: 2026, month: 9, day: 27, hour: 0, minute: 30)))
        let result = HistoryList.sections([beforeChange], doses: [], now: afterChange, calendar: calendar)
        #expect(result.map(\.header) == [.yesterday])
    }

    @Test func aDateAfterTodaySitsOnTopUnderItsOwnDateHeader() throws {
        let tomorrow = try entry(at: at(9, day: 29))
        let today = try entry(at: at(9))
        let tomorrowStart = try at(0, day: 29)
        let result = sections([today, tomorrow])
        #expect(result.map(\.header) == [.date(tomorrowStart, includesYear: false), .today])
    }

    @Test func anEntryFromYearsAgoStillGetsASection() throws {
        let tenYearsBack = try entry(at: date(DateComponents(year: 2016, month: 10, day: 28, hour: 9)))
        let today = try entry(at: at(9))
        let tenYearsBackStart = try date(DateComponents(year: 2016, month: 10, day: 28))
        let result = sections([tenYearsBack, today])
        #expect(result.map(\.header) == [.today, .date(tenYearsBackStart, includesYear: true)])
    }

    @Test func aDayWithOnlyDosesHasASection() throws {
        let taken = try dose(at: at(9))
        let result = sections([], doses: [taken])
        #expect(result.map(\.header) == [.today])
        #expect(result.map { $0.items.map(\.id) } == [[taken.id]])
    }

    @Test func entriesAndDosesOfOneDayShareItsSectionNewestFirst() throws {
        let morning = try entry(at: at(8))
        let lunch = try dose(at: at(13))
        let evening = try entry(at: at(20))
        let result = sections([morning, evening], doses: [lunch])
        #expect(result.map { $0.items.map(\.id) } == [[evening.id, lunch.id, morning.id]])
    }

    @Test func aDoseOnlyDayHeadsItsSectionAsTodayYesterdayOrItsDate() throws {
        let today = try dose(at: at(9))
        let yesterday = try dose(at: at(20, day: 27))
        let tenYearsBack = try dose(at: date(DateComponents(year: 2016, month: 10, day: 28, hour: 9)))
        let tenYearsBackStart = try date(DateComponents(year: 2016, month: 10, day: 28))
        let result = sections([], doses: [today, yesterday, tenYearsBack])
        #expect(result.map(\.header) == [.today, .yesterday, .date(tenYearsBackStart, includesYear: true)])
    }

    @Test(arguments: StoreKind.allCases) func anEntryMovedToYesterdayLeavesTodaysSectionAndJoinsYesterdays(
        _ kind: StoreKind
    ) throws {
        let today = try entry(at: at(9))
        let otherYesterday = try entry(at: at(9, day: 27))
        var log = try EntryLog(store: kind.fixture(holding: [today, otherYesterday]).store)
        var draft = EntryDraft(entry: today)
        draft.date = try at(23, 50, day: 27)
        let moved = Entry(id: today.id, draft: draft)
        try log.replace(moved)
        let result = HistoryList.sections(log.entries, doses: [], now: now, calendar: calendar)
        #expect(result.map(\.header) == [.yesterday])
        let yesterday = try #require(result.first)
        #expect(yesterday.items.map(\.id) == [moved.id, otherYesterday.id])
    }
}
