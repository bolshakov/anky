// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationDraftChangesTests {
    private let nineOClock = DoseTime(hour: 9, minute: 0)!
    private let start = ScheduleDay(year: 2026, month: 11, day: 11)!

    private func schedule(times: [DoseTime]? = nil) throws -> MedicationSchedule {
        try MedicationSchedule(repeat: .days(1), times: times ?? [nineOClock], start: start, end: nil)
    }

    private func scheduledDraft() throws -> MedicationDraft {
        var draft = MedicationDraft()
        draft.name = "Zorblex"
        draft.takenAs = .scheduled
        draft.schedule = try schedule()
        return draft
    }

    @Test func anUntouchedNewDraftHasNoChange() {
        let opening = MedicationDraft()
        #expect(!opening.hasChanges(since: opening))
    }

    @Test func aNameTypedAndDeletedBackToEmptyIsNoChange() {
        let opening = MedicationDraft()
        var draft = opening
        draft.name = "Z"
        draft.name = ""
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func aNameTypedIsAChange() {
        let opening = MedicationDraft()
        var draft = opening
        draft.name = "Zorblex"
        #expect(draft.hasChanges(since: opening))
    }

    @Test(arguments: [" ", "\n\t "])
    func blanksTypedIntoTheNameOrStrengthAreNoChange(blanks: String) {
        let opening = MedicationDraft()
        var draft = opening
        draft.name = blanks
        draft.strength = blanks
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func spacesAroundASavedNameAreNoChange() {
        var opening = MedicationDraft()
        opening.name = "Zorblex"
        var draft = opening
        draft.name = "  Zorblex "
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func aStrengthTypedIsAChange() {
        let opening = MedicationDraft()
        var draft = opening
        draft.strength = "50 mg"
        #expect(draft.hasChanges(since: opening))
    }

    @Test func aNameChangedAndPutBackIsNoChange() throws {
        let opening = try scheduledDraft()
        var draft = opening
        draft.name = "Other"
        draft.name = "Zorblex"
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func theChoiceChangedIsAChange() throws {
        let opening = try scheduledDraft()
        var draft = opening
        draft.takenAs = .asNeeded
        #expect(draft.hasChanges(since: opening))
    }

    @Test func aScheduleLeftBehindAfterTheChoiceWentBackToAsNeededIsNoChange() throws {
        var opening = MedicationDraft()
        opening.name = "Zorblex"
        var draft = opening
        draft.takenAs = .scheduled
        draft.schedule = try schedule()
        draft.takenAs = .asNeeded
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func aScheduleChangedOnAScheduledMedicationIsAChange() throws {
        let opening = try scheduledDraft()
        var draft = opening
        draft.schedule = try schedule(times: [#require(DoseTime(hour: 21, minute: 0))])
        #expect(draft.hasChanges(since: opening))
    }

    @Test func aDelayChosenWhileTheSwitchIsOnIsAChange() {
        var opening = MedicationDraft()
        opening.checkIn = DoseCheckIn(savedDelay: .oneHour)
        var draft = opening
        draft.checkIn.delay = .threeHours
        #expect(draft.hasChanges(since: opening))
    }

    @Test func aDelayMovedWhileTheSwitchIsOffIsNoChange() {
        let opening = MedicationDraft()
        var draft = opening
        draft.checkIn.delay = .fourHours
        #expect(!draft.hasChanges(since: opening))
    }

    @Test func theSwitchTurnedOnIsAChange() {
        let opening = MedicationDraft()
        var draft = opening
        draft.checkIn.isOn = true
        #expect(draft.hasChanges(since: opening))
    }

    @Test func aSavedMedicationOpenedAndLeftAloneHasNoChange() throws {
        let saved = try scheduledDraft().medication(id: UUID(), at: Date(timeIntervalSince1970: 1_800_000_000))
        let opening = MedicationDraft(saved)
        #expect(!opening.hasChanges(since: opening))
    }
}
