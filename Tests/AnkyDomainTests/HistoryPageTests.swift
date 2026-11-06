// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct HistoryPageTests {
    private let calendar: Calendar
    private let now: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        now = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)))
    }

    private func moment(daysBack: Int, hour: Int = 9, minute: Int = 0) throws -> Date {
        let day = try #require(calendar.date(byAdding: .day, value: -daysBack, to: now))
        return try #require(calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day))
    }

    private func entry(daysBack: Int, hour: Int = 9, minute: Int = 0) throws -> Entry {
        try Entry(draft: EntryDraft(
            severity: #require(Severity(4)),
            date: moment(daysBack: daysBack, hour: hour, minute: minute)
        ))
    }

    private func dose(daysBack: Int, hour: Int = 9, before: UUID? = nil) throws -> Dose {
        try Dose(
            id: UUID(),
            medicationID: UUID(),
            takenAt: moment(daysBack: daysBack, hour: hour),
            beforeReadingID: before
        )
    }

    private func oneEntryPerDay(_ days: Range<Int>) throws -> [Entry] {
        try days.map { try entry(daysBack: $0) }
    }

    private func page(_ entries: [Entry], doses: [Dose] = [], days: Int = HistoryList.pageDays) -> HistoryPage {
        HistoryList.page(entries, doses: doses, window: HistoryWindow(days: days, now: now, calendar: calendar))
    }

    private func whole(_ entries: [Entry], doses: [Dose] = []) -> [DaySection] {
        HistoryList.sections(entries, doses: doses, now: now, calendar: calendar)
    }

    /// The sections the page holds are the newest days of the whole log, item for item.
    private func expectPageMatchesWholeLog(
        _ entries: [Entry], doses: [Dose] = [], days: Int = HistoryList.pageDays
    ) {
        let all = whole(entries, doses: doses)
        let result = page(entries, doses: doses, days: days)
        #expect(result.sections == Array(all.prefix(days)))
        #expect(result.hasOlderDays == (all.count > days))
    }

    @Test func aPageIsThirtyDays() {
        #expect(HistoryList.pageDays == 30)
    }

    @Test func aPageHoldsTheNewestDaysOfTheWholeLogAndSaysOlderDaysRemain() throws {
        let entries = try oneEntryPerDay(0 ..< 45)
        let result = page(entries)
        #expect(result.sections.count == 30)
        #expect(result.hasOlderDays)
        expectPageMatchesWholeLog(entries)
    }

    @Test func aLogOfExactlyThirtyDaysHasNoOlderDaysAndOneOfThirtyOneHasOne() throws {
        let thirty = try oneEntryPerDay(0 ..< 30)
        #expect(page(thirty).sections.count == 30)
        #expect(!page(thirty).hasOlderDays)

        let thirtyOne = try oneEntryPerDay(0 ..< 31)
        #expect(page(thirtyOne).sections.count == 30)
        #expect(page(thirtyOne).hasOlderDays)
        let next = page(thirtyOne, days: 60)
        #expect(next.sections.count == 31)
        #expect(!next.hasOlderDays)
        #expect(next.sections.last?.items.map(\.id) == [thirtyOne[30].id])
    }

    @Test func aShortLogOrNoLogHasNoOlderDays() throws {
        #expect(page([]).sections.isEmpty)
        #expect(!page([]).hasOlderDays)
        let short = try oneEntryPerDay(0 ..< 3)
        #expect(page(short).sections.count == 3)
        #expect(!page(short).hasOlderDays)
    }

    @Test func aDayWithOnlyADoseCountsAsADay() throws {
        let entries = try oneEntryPerDay(0 ..< 29)
        let doses = try [dose(daysBack: 29), dose(daysBack: 30)]
        let result = page(entries, doses: doses)
        #expect(result.sections.last?.items.map(\.id) == [doses[0].id])
        #expect(result.hasOlderDays)
    }

    @Test func aBusyDayOnTheEdgeShowsOnceAndWholeAndNoItemRepeatsAcrossPages() throws {
        var entries = try oneEntryPerDay(0 ..< 29)
        let edge = try [entry(daysBack: 29, hour: 8), entry(daysBack: 29, hour: 14), entry(daysBack: 29, hour: 14)]
        let edgeDose = try dose(daysBack: 29, hour: 14)
        entries += edge
        entries += try oneEntryPerDay(30 ..< 40)

        let first = page(entries, doses: [edgeDose])
        let edgeSection = try #require(first.sections.last)
        #expect(Set(edgeSection.items.map(\.id)) == Set(edge.map(\.id) + [edgeDose.id]))
        #expect(edgeSection.items.count == 4)
        expectPageMatchesWholeLog(entries, doses: [edgeDose])

        let second = page(entries, doses: [edgeDose], days: 2 * HistoryList.pageDays)
        let added = second.sections.dropFirst(first.sections.count).flatMap(\.items).map(\.id)
        let shownFirst = first.sections.flatMap(\.items).map(\.id)
        #expect(Set(added).isDisjoint(with: shownFirst))
        #expect(Array(second.sections.prefix(first.sections.count)) == first.sections)
        #expect(Set(second.sections.flatMap(\.items).map(\.id)).count == 4 + 29 + 10)
    }

    @Test func anEntryLoggedLateForAnEarlierDayLandsInThatDaysPage() throws {
        var entries = try oneEntryPerDay(0 ..< 45)
        let lateForDayTen = try entry(daysBack: 10, hour: 7)
        let lateForDayForty = try entry(daysBack: 40, hour: 7)
        entries += [lateForDayTen, lateForDayForty]

        let first = page(entries)
        let ten = try #require(first.sections.first { $0.id == calendar.startOfDay(for: lateForDayTen.date) })
        #expect(ten.items.map(\.id).contains(lateForDayTen.id))
        #expect(!first.sections.flatMap(\.items).map(\.id).contains(lateForDayForty.id))
        #expect(first.sections.count == 30)
        expectPageMatchesWholeLog(entries)

        let second = page(entries, days: 2 * HistoryList.pageDays)
        let forty = try #require(second.sections.first { $0.id == calendar.startOfDay(for: lateForDayForty.date) })
        #expect(forty.items.map(\.id).contains(lateForDayForty.id))
        expectPageMatchesWholeLog(entries, days: 2 * HistoryList.pageDays)
    }

    @Test func pagesFollowTheDateAndNotTheSaveOrder() throws {
        let entries = try oneEntryPerDay(0 ..< 45).reversed().map(\.self)
        let result = page(entries)
        #expect(result.sections.first?.header == .today)
        #expect(result.sections.map(\.id) == result.sections.map(\.id).sorted(by: >))
        expectPageMatchesWholeLog(entries)
    }

    @Test func sameMinuteItemsKeepTheWholeLogOrderOnAPage() throws {
        var entries = try oneEntryPerDay(1 ..< 40)
        for _ in 0 ..< 3 {
            try entries.append(entry(daysBack: 0, minute: 30))
        }
        let doses = try [dose(daysBack: 0), dose(daysBack: 0)]
        expectPageMatchesWholeLog(entries, doses: doses)
        #expect(page(entries, doses: doses).sections.first?.items.count == 5)
    }

    @Test func aDoseOnThePageFindsItsReadingOnADayPastTheEdge() throws {
        var entries = try oneEntryPerDay(0 ..< 40)
        let reading = try entry(daysBack: 45)
        entries.append(reading)
        let taken = try dose(daysBack: 0, hour: 10, before: reading.id)

        let result = page(entries, doses: [taken])
        #expect(!result.sections.flatMap(\.items).map(\.id).contains(reading.id))
        let byID = EntriesByID(entries)
        #expect(DoseReadings(taken, in: byID) == DoseReadings(taken, in: entries))
        #expect(DoseReadings(taken, in: byID).before == reading)
    }

    @Test func aSaveOnANewDayKeepsTheCountAndPushesTheOldestDayBelowTheCut() throws {
        var entries = try oneEntryPerDay(1 ..< 61)
        let before = page(entries, days: 60)
        #expect(before.sections.count == 60)
        #expect(!before.hasOlderDays)

        let firstOfNewDay = try entry(daysBack: 0, hour: 0, minute: 1)
        entries.append(firstOfNewDay)
        let after = page(entries, days: 60)
        #expect(after.sections.count == 60)
        #expect(after.sections.first?.items.map(\.id) == [firstOfNewDay.id])
        #expect(after.hasOlderDays)
        #expect(after.sections.dropFirst() == before.sections.dropLast())
        expectPageMatchesWholeLog(entries, days: 60)
    }

    @Test func deletingTheOnlyItemOfADayPullsTheNextOlderDayInWithNoGapAndNoRepeat() throws {
        let entries = try oneEntryPerDay(0 ..< 70)
        let before = page(entries, days: 60)
        #expect(before.hasOlderDays)

        let remaining = entries.filter { $0.id != entries[5].id }
        let after = page(remaining, days: 60)
        #expect(after.sections.count == 60)
        #expect(after.sections.last?.items.map(\.id) == [entries[60].id])
        let ids = after.sections.flatMap(\.items).map(\.id)
        #expect(Set(ids).count == ids.count)
        expectPageMatchesWholeLog(remaining, days: 60)
    }

    @Test func deletingTheLastOlderDayEndsThePaging() throws {
        let entries = try oneEntryPerDay(0 ..< 31)
        let remaining = Array(entries.dropLast())
        #expect(page(entries).hasOlderDays)
        #expect(!page(remaining).hasOlderDays)
    }

    @Test func editingAnEntryToADayOlderThanEveryShownDayMovesItOutOfThePage() throws {
        var entries = try oneEntryPerDay(0 ..< 60)
        var draft = EntryDraft(entry: entries[3])
        draft.date = try moment(daysBack: 55)
        let moved = Entry(id: entries[3].id, draft: draft)
        entries[3] = moved

        let result = page(entries, days: 30)
        #expect(!result.sections.flatMap(\.items).map(\.id).contains(moved.id))
        #expect(result.sections.count == 30)
        #expect(result.hasOlderDays)
        expectPageMatchesWholeLog(entries)

        let scrolled = page(entries, days: 60)
        let day = try #require(scrolled.sections.first { $0.id == calendar.startOfDay(for: moved.date) })
        #expect(day.items.map(\.id).contains(moved.id))
    }

    @Test func midnightPassingMovesTheHeadersAndKeepsTheShownDays() throws {
        let entries = try oneEntryPerDay(0 ..< 45)
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: now))
        let window = HistoryWindow(days: 30, now: tomorrow, calendar: calendar)
        let result = HistoryList.page(entries, doses: [], window: window)
        #expect(result.sections.map(\.id) == page(entries).sections.map(\.id))
        #expect(result.sections.first?.header == .yesterday)
        #expect(result.hasOlderDays)
    }

    @Test func aNonPositiveCountShowsNothingAndStillSaysOlderDaysRemain() throws {
        let entries = try oneEntryPerDay(0 ..< 3)
        #expect(page(entries, days: 0).sections.isEmpty)
        #expect(page(entries, days: 0).hasOlderDays)
        #expect(page(entries, days: -5).sections.isEmpty)
    }
}
