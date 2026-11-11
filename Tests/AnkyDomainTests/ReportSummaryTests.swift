// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportSummaryTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private var start: Date {
        get throws { try ReportPeriod.oneMonth.start(endingAt: now, calendar: calendar) }
    }

    private func entry(at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(4)), date: date, note: nil, places: [])
    }

    private func dose(at date: Date) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: date)
    }

    private func summary(entries: [Entry] = [], doses: [Dose] = []) throws -> ReportSummary {
        try ReportSummary(entries: entries, doses: doses, period: .oneMonth, now: now, calendar: calendar)
    }

    @Test func anEmptyLogIsEmpty() throws {
        let summary = try summary()
        #expect(summary.isEmpty)
        #expect(summary.entryCount == 0)
        #expect(summary.doseCount == 0)
        #expect(summary.firstEntry == nil)
    }

    @Test func oneEntryIsCountedAndIsTheFirstEntry() throws {
        let logged = try now.addingTimeInterval(-3 * 86400)
        let summary = try summary(entries: [entry(at: logged)])
        #expect(!summary.isEmpty)
        #expect(summary.entryCount == 1)
        #expect(summary.firstEntry == logged)
    }

    @Test func anEntryExactlyAtTheStartCounts() throws {
        let summary = try summary(entries: [entry(at: start)])
        #expect(summary.entryCount == 1)
        #expect(try summary.firstEntry == start)
    }

    @Test func anEntryExactlyAtNowCounts() throws {
        let summary = try summary(entries: [entry(at: now)])
        #expect(summary.entryCount == 1)
    }

    @Test func entriesBeforeTheStartOrAfterNowDoNotCount() throws {
        let entries = try [entry(at: start.addingTimeInterval(-1)), entry(at: now.addingTimeInterval(1))]
        let summary = try summary(entries: entries)
        #expect(summary.entryCount == 0)
        #expect(summary.firstEntry == nil)
        #expect(summary.isEmpty)
    }

    @Test func dosesAtTheStartAndAtNowCountAndOutsideDoNot() throws {
        let inside = try [dose(at: start), dose(at: now)]
        let outside = try [dose(at: start.addingTimeInterval(-1)), dose(at: now.addingTimeInterval(1))]
        let doses = inside + outside
        #expect(try summary(doses: doses).doseCount == 2)
    }

    @Test func aDoseIsPlacedByWhenItWasTakenNotWhenItWasLogged() throws {
        var dose = try dose(at: start.addingTimeInterval(-60))
        dose.loggedAt = try now
        #expect(try summary(doses: [dose]).doseCount == 0)
    }

    @Test func theFirstEntryIsTheEarliestInThePeriodWhateverTheOrder() throws {
        let earliest = try start.addingTimeInterval(5 * 86400)
        let later = try entry(at: now.addingTimeInterval(-86400))
        let beforeStart = try entry(at: start.addingTimeInterval(-60))
        let entries = try [later, entry(at: earliest), beforeStart]
        let summary = try summary(entries: entries)
        #expect(summary.entryCount == 2)
        #expect(summary.firstEntry == earliest)
    }

    @Test func dosesAloneAreNotEmptyAndHaveNoFirstEntry() throws {
        let summary = try summary(doses: [dose(at: now.addingTimeInterval(-60))])
        #expect(!summary.isEmpty)
        #expect(summary.firstEntry == nil)
    }

    @Test func aLongerPeriodCountsOlderEntries() throws {
        let twoMonthsAgo = try now.addingTimeInterval(-61 * 86400)
        let entries = try [entry(at: twoMonthsAgo)]
        let summary = try ReportSummary(entries: entries, doses: [], period: .threeMonths, now: now, calendar: calendar)
        #expect(summary.entryCount == 1)
        #expect(try self.summary(entries: entries).entryCount == 0)
    }
}
