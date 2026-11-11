// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ScheduleDraftDatesTests {
    private let start = ScheduleDay(year: 2026, month: 11, day: 11)!

    private func day(_ month: Int, _ day: Int, year: Int = 2026) -> ScheduleDay {
        ScheduleDay(year: year, month: month, day: day)!
    }

    private func draft(end: ScheduleDay? = nil) -> ScheduleDraft {
        var draft = ScheduleDraft(startingOn: start, calendar: Calendar(identifier: .gregorian))
        draft.end = end
        return draft
    }

    @Test func setStartMovesTheStartAndLeavesAnEndAfterItAlone() {
        var draft = draft(end: day(12, 1))
        draft.setStart(day(11, 20))
        #expect(draft.start == day(11, 20))
        #expect(draft.end == day(12, 1))
    }

    @Test func setStartLeavesNoEndUnset() {
        var draft = draft()
        draft.setStart(day(11, 20))
        #expect(draft.end == nil)
    }

    @Test func setStartMovesAnEndThatWouldFallBeforeUpToTheStart() {
        var draft = draft(end: day(11, 15))
        draft.setStart(day(11, 20))
        #expect(draft.start == day(11, 20))
        #expect(draft.end == day(11, 20))
    }

    @Test func setStartOnTheEndDayKeepsTheEnd() {
        var draft = draft(end: day(11, 15))
        draft.setStart(day(11, 15))
        #expect(draft.end == day(11, 15))
    }

    @Test func setStartAcrossAYearBoundaryComparesTheYearFirst() {
        var draft = draft(end: day(12, 31))
        draft.setStart(day(1, 1, year: 2027))
        #expect(draft.end == day(1, 1, year: 2027))
    }

    @Test func setEndAfterTheStartIsKept() {
        var draft = draft()
        draft.setEnd(day(12, 24))
        #expect(draft.end == day(12, 24))
    }

    @Test func setEndOnTheStartIsKept() {
        var draft = draft()
        draft.setEnd(start)
        #expect(draft.end == start)
    }

    @Test func setEndBeforeTheStartBecomesTheStart() {
        var draft = draft()
        draft.setEnd(day(11, 1))
        #expect(draft.end == start)
    }

    @Test func setEndBeforeTheStartInAnEarlierYearBecomesTheStart() {
        var draft = draft()
        draft.setEnd(day(12, 31, year: 2025))
        #expect(draft.end == start)
    }

    @Test func setEndToNilClearsTheEnd() {
        var draft = draft(end: day(12, 24))
        draft.setEnd(nil)
        #expect(draft.end == nil)
    }

    @Test func aDraftBuiltAfterEitherSetterNeverHasAnEndBeforeItsStart() throws {
        var draft = draft(end: day(11, 15))
        draft.setStart(day(11, 20))
        draft.setEnd(day(11, 2))
        let schedule = try #require(draft.schedule())
        let end = try #require(schedule.end)
        #expect(end == schedule.start)
    }
}
