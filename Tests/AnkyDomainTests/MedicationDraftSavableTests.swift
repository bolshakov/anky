// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationDraftSavableTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft(_ takenAs: TakenAs, _ schedule: MedicationSchedule? = nil) -> MedicationDraft {
        var draft = MedicationDraft()
        draft.name = "Zorblex"
        draft.takenAs = takenAs
        draft.schedule = schedule
        return draft
    }

    private func everyDay() throws -> MedicationSchedule {
        try MedicationSchedule(
            repeat: .days(1), times: [#require(DoseTime(hour: 9, minute: 0))],
            start: #require(ScheduleDay(year: 2026, month: 11, day: 1)), end: nil
        )
    }

    @Test func anAsNeededDraftNeedsNoSchedule() {
        #expect(draft(.asNeeded).isSavable)
    }

    @Test func aScheduledDraftWithNoScheduleIsNotSavable() {
        #expect(!draft(.scheduled).isSavable)
    }

    @Test func aScheduledDraftWithAScheduleIsSavable() throws {
        #expect(try draft(.scheduled, everyDay()).isSavable)
    }

    @Test func aScheduledDraftWithAScheduleAndNoNameIsNotSavable() throws {
        var draft = try draft(.scheduled, everyDay())
        draft.name = "  "
        #expect(!draft.isSavable)
    }

    @Test func switchingToAsNeededAndBackKeepsTheSetScheduleUntilSaved() throws {
        let schedule = try everyDay()
        var draft = draft(.scheduled, schedule)
        draft.takenAs = .asNeeded
        #expect(draft.isSavable)
        #expect(draft.medication(id: UUID(), at: date).schedule == nil)
        draft.takenAs = .scheduled
        #expect(draft.schedule == schedule)
        #expect(draft.medication(id: UUID(), at: date).schedule == schedule)
    }
}
