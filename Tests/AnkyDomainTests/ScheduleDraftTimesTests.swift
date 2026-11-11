// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let wednesday = ScheduleDay(year: 2026, month: 11, day: 11)!

private func time(_ hour: Int, _ minute: Int = 0) -> DoseTime {
    DoseTime(hour: hour, minute: minute)!
}

struct ScheduleDraftTimesTests {
    private func draft(holding times: [DoseTime]) -> ScheduleDraft {
        var draft = ScheduleDraft(startingOn: wednesday, calendar: Calendar(identifier: .gregorian))
        draft.times = times
        return draft
    }

    @Test func addingATimeToNineGivesASecondRowAnHourLater() {
        var draft = draft(holding: [time(9)])
        draft.addTime()
        #expect(draft.times == [time(9), time(10)])
    }

    @Test func addingATimeFollowsTheLastTimeTheWayThePersonHasThem() {
        var draft = draft(holding: [time(20), time(8)])
        draft.addTime()
        #expect(draft.times == [time(20), time(8), time(9)])
    }

    @Test func addingATimeWrapsPastMidnight() {
        var draft = draft(holding: [time(23, 30)])
        draft.addTime()
        #expect(draft.times == [time(23, 30), time(0, 30)])
    }

    @Test func addingATimeMovesOnAMinuteAtATimeWhenTheHourLaterIsTaken() {
        var draft = draft(holding: [time(10), time(9)])
        draft.addTime()
        #expect(draft.times == [time(10), time(9), time(10, 1)])
    }

    @Test func addingATimeKeepsMovingOnPastSeveralTakenMinutes() {
        var draft = draft(holding: [time(10, 0), time(10, 1), time(10, 2), time(9)])
        draft.addTime()
        #expect(draft.times.last == time(10, 3))
    }

    @Test func addingATimeAlwaysAddsARowWhileAMinuteIsFree() {
        var draft = draft(holding: [time(9)])
        for expected in 2 ... 30 {
            draft.addTime()
            #expect(draft.times.count == expected)
            #expect(Set(draft.times).count == expected)
        }
    }

    @Test func addingATimeToAFullDayChangesNothing() {
        let everyMinute = (0 ..< 24 * 60).map { time($0 / 60, $0 % 60) }
        var draft = draft(holding: everyMinute)
        draft.addTime()
        #expect(draft.times == everyMinute)
    }

    @Test func removingATimeTakesThatRowOnly() {
        var draft = draft(holding: [time(8), time(12), time(20)])
        draft.removeTime(at: 1)
        #expect(draft.times == [time(8), time(20)])
    }

    @Test func theLastTimeCannotBeRemoved() {
        var draft = draft(holding: [time(9)])
        draft.removeTime(at: 0)
        #expect(draft.times == [time(9)])
    }

    @Test func removingDownToOneTimeStopsThere() {
        var draft = draft(holding: [time(8), time(12)])
        draft.removeTime(at: 0)
        draft.removeTime(at: 0)
        #expect(draft.times == [time(12)])
    }

    @Test(arguments: [-1, 2])
    func removingARowThatIsNotThereChangesNothing(_ index: Int) {
        var draft = draft(holding: [time(8), time(12)])
        draft.removeTime(at: index)
        #expect(draft.times == [time(8), time(12)])
    }

    @Test func twoRowsEditedToTheSameTimeBuildOneTimeInTheSchedule() throws {
        let draft = draft(holding: [time(9), time(9), time(8)])
        #expect(try #require(draft.schedule()).times == [time(8), time(9)])
        #expect(draft.times.count == 3)
    }
}
