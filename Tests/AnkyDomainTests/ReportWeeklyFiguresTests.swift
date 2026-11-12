// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportWeeklyFiguresTests {
    private static func calendar(_ locale: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }

    private let german = Self.calendar("de_DE")
    private let american = Self.calendar("en_US")

    private func date(_ day: Int, month: Int = 11, hour: Int = 0, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)))
    }

    /// Wednesday 11 November 2026, 15:00. A month back starts on Sunday 11 October.
    private func now(in calendar: Calendar) throws -> Date {
        try date(11, hour: 15, in: calendar)
    }

    private func entry(_ kind: EntryKind = .pain, _ severity: Int = 4, at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(severity)), date: date, note: nil, places: [])
    }

    private func figures(_ entries: [Entry], in calendar: Calendar) throws -> ReportWeeklyFigures {
        try ReportWeeklyFigures(entries: entries, period: .oneMonth, now: now(in: calendar), calendar: calendar)
    }

    private func pain(_ figures: ReportWeeklyFigures) throws -> KindWeeklyFigures {
        try #require(figures.kinds.first { $0.kind == .pain })
    }

    private func mark(of severities: [Int]) throws -> WeekMark {
        let tuesday = try date(10, hour: 9, in: german)
        let entries = try severities.enumerated().map { offset, severity in
            try entry(.pain, severity, at: tuesday.addingTimeInterval(Double(offset) * 60))
        }
        return try #require(pain(figures(entries, in: german)).weeks.last).mark
    }

    private func severity(_ value: Int) throws -> Severity {
        try #require(Severity(value))
    }

    @Test func theCalendarsStartTheirWeeksOnMondayAndSunday() {
        #expect(german.firstWeekday == 2)
        #expect(american.firstWeekday == 1)
    }

    @Test func aGermanAxisRunsMondaysFromTheWeekOfTheStartToTheWeekOfNow() throws {
        let figures = try figures([], in: german)
        let mondays = try [date(5, month: 10, in: german), date(12, month: 10, in: german),
                           date(19, month: 10, in: german), date(26, month: 10, in: german),
                           date(2, in: german), date(9, in: german)]
        #expect(figures.weekStarts == mondays)
    }

    @Test func anAmericanAxisRunsSundaysFromTheWeekOfTheStartToTheWeekOfNow() throws {
        let figures = try figures([], in: american)
        let sundays = try [date(11, month: 10, in: american), date(18, month: 10, in: american),
                           date(25, month: 10, in: american), date(1, in: american), date(8, in: american)]
        #expect(figures.weekStarts == sundays)
    }

    @Test func aSundayEntryJoinsTheWeekItEndsInGermanyAndTheWeekItStartsInAmerica() throws {
        let sunday = try date(8, hour: 12, in: german)
        let germanWeeks = try pain(figures([entry(at: sunday)], in: german)).weeks
        let americanWeeks = try pain(figures([entry(at: sunday)], in: american)).weeks
        #expect(try germanWeeks.first { $0.count == 1 }?.weekStart == date(2, in: german))
        #expect(try americanWeeks.first { $0.count == 1 }?.weekStart == date(8, in: american))
    }

    @Test func entriesOnThePeriodsFirstDayAndAtNowCountInThePartialFirstAndLastWeeks() throws {
        let start = try ReportPeriod.oneMonth.start(endingAt: now(in: german), calendar: german)
        let weeks = try pain(figures([entry(at: start), entry(at: now(in: german))], in: german)).weeks
        #expect(weeks.first?.count == 1)
        #expect(weeks.last?.count == 1)
    }

    @Test func entriesBeforeThePeriodsStartOrAfterNowAreLeftOut() throws {
        let start = try ReportPeriod.oneMonth.start(endingAt: now(in: german), calendar: german)
        let outside = try [entry(at: start.addingTimeInterval(-1)), entry(at: now(in: german).addingTimeInterval(1))]
        let figures = try pain(figures(outside, in: german))
        #expect(!figures.hasEntries)
        #expect(figures.weeks.allSatisfy { $0.count == 0 && $0.mark == .none })
    }

    @Test func anEntryAtAWeeksFirstInstantJoinsThatWeekAndOneASecondEarlierThePreviousWeek() throws {
        let monday = try date(26, month: 10, in: german)
        let entries = try [entry(at: monday), entry(at: monday.addingTimeInterval(-1))]
        let weeks = try pain(figures(entries, in: german)).weeks
        let counts = weeks.map(\.count)
        #expect(try weeks.map(\.weekStart)[2 ... 3] == [date(19, month: 10, in: german), monday])
        #expect(counts == [0, 0, 1, 1, 0, 0])
    }

    @Test func aWeekWithNoEntryHasNoMark() throws {
        #expect(try mark(of: []) == .none)
    }

    @Test func aWeekWithOneEntryHasThatSingleValue() throws {
        #expect(try mark(of: [7]) == .single(severity(7)))
    }

    @Test func aWeekWithTwoEntriesHasARangeAroundTheirAverage() throws {
        #expect(try mark(of: [3, 8]) == .range(average: 5.5, lowest: severity(3), highest: severity(8)))
    }

    @Test func aWeekWithThreeEntriesHasARangeAroundTheirAverage() throws {
        #expect(try mark(of: [6, 2, 4]) == .range(average: 4, lowest: severity(2), highest: severity(6)))
    }

    @Test func aWeekWhereEveryEntryIsEqualIsARangeWithNoLengthNotADot() throws {
        #expect(try mark(of: [4, 4]) == .range(average: 4, lowest: severity(4), highest: severity(4)))
    }

    @Test func aWeekCountsItsEntries() throws {
        let tuesday = try date(10, hour: 9, in: german)
        let entries = try [entry(at: tuesday), entry(at: tuesday), entry(at: tuesday)]
        #expect(try pain(figures(entries, in: german)).weeks.last?.count == 3)
    }

    @Test func everyKindIsListedInOrderWithItsOwnEntriesOnly() throws {
        let tuesday = try date(10, hour: 9, in: german)
        let entries = try [entry(.fatigue, 9, at: tuesday), entry(.pain, 2, at: tuesday)]
        let figures = try figures(entries, in: german)
        #expect(figures.kinds.map(\.kind) == EntryKind.allCases)
        #expect(try figures.kinds.map { $0.weeks.last?.mark } == [.single(severity(2)), WeekMark.none,
                                                                  .single(severity(9))])
    }

    @Test func aKindWithNoEntriesStillHasEveryAxisWeekEmpty() throws {
        let figures = try figures([entry(.pain, at: date(10, hour: 9, in: german))], in: german)
        let stiffness = try #require(figures.kinds.first { $0.kind == .stiffness })
        #expect(stiffness.weeks.map(\.weekStart) == figures.weekStarts)
        #expect(stiffness.weeks.allSatisfy { $0.count == 0 && $0.mark == .none })
        #expect(!stiffness.hasEntries)
        #expect(stiffness.loggedWeekCount == 0)
    }

    @Test func aKindCountsTheWeeksItWasLoggedIn() throws {
        let entries = try [entry(at: date(13, month: 10, in: german)), entry(at: date(14, month: 10, in: german)),
                           entry(at: date(10, in: german))]
        let pain = try pain(figures(entries, in: german))
        #expect(pain.hasEntries)
        #expect(pain.loggedWeekCount == 2)
    }
}
