// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportTotalsTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private func entry(at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(4)), date: date, note: nil, places: [])
    }

    private func dose(at date: Date) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: date)
    }

    private func totals(
        entries: [Date],
        doses: [Date] = [],
        basdaiCount: Int = 0,
        in locale: Locale = Locale(identifier: "en_GB")
    ) throws -> ReportTotalsText {
        let summary = try ReportSummary(
            entries: entries.map(entry), doses: doses.map(dose), period: .threeMonths, now: now, calendar: calendar
        )
        return try CompiledCatalog.withBundle("en") {
            ReportTotalsText(summary: summary, basdaiCount: basdaiCount, locale: locale, calendar: calendar, bundle: $0)
        }
    }

    private func day(_ month: Int, _ day: Int, hour: Int = 10) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)))
    }

    @Test func theTotalsCountEntriesAndDosesAndNameTheFirstEntry() throws {
        let totals = try totals(entries: [day(9, 3), day(8, 12), day(10, 1)], doses: [day(9, 1), day(9, 2)])
        #expect(totals.entries == "3 entries")
        #expect(totals.doses == "2 doses")
        #expect(totals.firstEntry == "First entry 12 August")
    }

    @Test func oneEntryAndOneDoseAreSingular() throws {
        let totals = try totals(entries: [day(9, 3)], doses: [day(9, 1)])
        #expect(totals.entries == "1 entry")
        #expect(totals.doses == "1 dose")
    }

    @Test func dosesAloneNameNoFirstEntry() throws {
        let totals = try totals(entries: [], doses: [day(9, 1)])
        #expect(totals.entries == "0 entries")
        #expect(totals.firstEntry == nil)
    }

    @Test func aFirstEntryOnThePeriodsFirstDayShowsThatDay() throws {
        #expect(try totals(entries: [day(8, 11, hour: 0)]).firstEntry == "First entry 11 August")
    }

    @Test func aFirstEntryOnThePeriodsLastDayShowsThatDay() throws {
        #expect(try totals(entries: [now]).firstEntry == "First entry 11 November")
    }

    @Test func theFirstEntryFollowsTheRegionsOrder() throws {
        #expect(
            try totals(entries: [day(8, 12)], in: Locale(identifier: "en_US")).firstEntry == "First entry August 12"
        )
    }

    @Test func theTotalsCountTheBasdaiResults() throws {
        #expect(try totals(entries: [day(9, 3)], basdaiCount: 3).basdai == "3 BASDAI results")
    }

    @Test func oneBasdaiResultIsSingular() throws {
        #expect(try totals(entries: [day(9, 3)], basdaiCount: 1).basdai == "1 BASDAI result")
    }

    @Test func noBasdaiResultsLeaveTheLineOut() throws {
        #expect(try totals(entries: [day(9, 3)]).basdai == nil)
        #expect(try totals(entries: [day(9, 3)], basdaiCount: 0).basdai == nil)
    }
}
