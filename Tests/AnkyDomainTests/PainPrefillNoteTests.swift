// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PainPrefillNoteTests {
    private let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
    }

    private func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )))
    }

    private func note(
        entryAt date: Date,
        now: Date,
        _ identifier: String = "en_GB"
    ) throws -> PainPrefillNote {
        let entry = try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(3)),
            date: date,
            note: nil,
            places: []
        )
        return PainPrefillNote(
            entry: entry,
            now: now,
            calendar: calendar,
            locale: Locale(identifier: identifier)
        )
    }

    @Test func anEntryEarlierTodayReadsItsClockOnly() throws {
        let now = try moment(2026, 11, 1, 12)
        #expect(try note(entryAt: moment(2026, 11, 1, 8, 15), now: now) ==
            PainPrefillNote(day: .today, clock: "08:15"))
    }

    @Test func anEntryFromYesterdayReadsYesterdayAndItsClock() throws {
        // 23:50 yesterday, seen at 00:10 today, is still yesterday.
        let now = try moment(2026, 11, 1, 0, 10)
        #expect(try note(entryAt: moment(2026, 10, 31, 23, 50), now: now) ==
            PainPrefillNote(day: .yesterday, clock: "23:50"))
    }

    @Test func anEntryEarlierThisYearReadsItsDayAndClock() throws {
        let now = try moment(2026, 11, 1)
        #expect(try note(entryAt: moment(2026, 10, 24, 8, 15), now: now) ==
            PainPrefillNote(day: .sameYear("Sat 24 Oct"), clock: "08:15"))
    }

    @Test func anEntryFromAnotherYearReadsItsDayYearAndClock() throws {
        let now = try moment(2026, 11, 1)
        #expect(try note(entryAt: moment(2025, 10, 24, 8, 15), now: now) ==
            PainPrefillNote(day: .otherYear(day: "Fri 24 Oct", year: "2025"), clock: "08:15"))
    }

    @Test func theUnitedStatesClockKeepsItsNarrowSpaceBeforeAmOrPm() throws {
        let now = try moment(2026, 11, 1)
        #expect(try note(entryAt: moment(2026, 11, 1, 8, 15), now: now, "en_US") ==
            PainPrefillNote(day: .today, clock: "8:15\u{202F}AM"))
    }
}
