// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ScheduleDraftWeekdaysTests {
    private let wednesday = ScheduleDay(year: 2026, month: 11, day: 11)!

    private func draft(on weekdays: Set<Locale.Weekday>) -> ScheduleDraft {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: Calendar(identifier: .gregorian))
        draft.weekdays = weekdays
        return draft
    }

    @Test func toggleSwitchesAWeekdayOn() {
        var draft = draft(on: [.wednesday])
        draft.toggle(.friday)
        #expect(draft.weekdays == [.wednesday, .friday])
    }

    @Test func toggleSwitchesAWeekdayOffWhileAnotherStaysOn() {
        var draft = draft(on: [.wednesday, .friday])
        draft.toggle(.friday)
        #expect(draft.weekdays == [.wednesday])
    }

    @Test func theLastWeekdayCannotBeSwitchedOff() {
        var draft = draft(on: [.wednesday])
        draft.toggle(.wednesday)
        #expect(draft.weekdays == [.wednesday])
    }

    @Test func switchingAnotherWeekdayOnThenOffLeavesTheFirst() {
        var draft = draft(on: [.wednesday])
        draft.toggle(.monday)
        draft.toggle(.monday)
        #expect(draft.weekdays == [.wednesday])
    }

    @Test func switchingEveryWeekdayOffInTurnStopsAtOne() {
        var draft = draft(on: [.monday, .tuesday, .wednesday])
        for day in [Locale.Weekday.monday, .tuesday, .wednesday] {
            draft.toggle(day)
        }
        #expect(draft.weekdays == [.wednesday])
        #expect(draft.schedule() != nil)
    }
}
