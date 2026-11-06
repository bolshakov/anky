// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInRemindersTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333)
    private let medicationID = UUID()
    private var due: Date {
        takenAt.addingTimeInterval(30 * 60)
    }

    private func medication() -> Medication {
        Medication(id: medicationID, name: "Zorblex", takenAs: .asNeeded, createdAt: takenAt)
    }

    private func dose(at time: Date? = nil, delay: CheckInDelay? = .thirtyMinutes, after: UUID? = nil) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medicationID, takenAt: time ?? takenAt)
        dose.checkInAfter = delay
        dose.afterReadingID = after
        return dose
    }

    private func entry(at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(6)), date: date, note: nil, places: [])
    }

    private func reminders(
        _ doses: [Dose],
        medications: [Medication]? = nil,
        entries: [Entry] = [],
        now: Date? = nil
    ) -> [CheckInReminder] {
        CheckInDue.reminders(
            doses: doses,
            medications: medications ?? [medication()],
            entries: entries,
            now: now ?? takenAt.addingTimeInterval(60)
        )
    }

    @Test func aDoseWhoseWindowWillOpenGetsOneReminderAtItsDueMoment() {
        let waiting = dose()
        #expect(reminders([waiting]) == [CheckInReminder(doseID: waiting.id, fireAt: due)])
    }

    @Test func theReminderUsesTheDosesOwnDelay() {
        let waiting = dose(delay: .twoHours)
        #expect(reminders([waiting]).map(\.fireAt) == [takenAt.addingTimeInterval(2 * 60 * 60)])
    }

    @Test func aDoseWhoseDueMomentHasPassedGetsNoReminder() {
        #expect(reminders([dose()], now: due.addingTimeInterval(1)).isEmpty)
    }

    @Test func aDoseDueThisVerySecondGetsNoReminder() {
        #expect(reminders([dose()], now: due).isEmpty)
    }

    @Test func aDoseOneSecondBeforeItsDueMomentGetsAReminder() {
        #expect(reminders([dose()], now: due.addingTimeInterval(-1)).count == 1)
    }

    @Test func aDoseWithCheckInOffGetsNoReminder() {
        #expect(reminders([dose(delay: nil)]).isEmpty)
    }

    @Test func aDoseOfAMissingMedicationGetsNoReminder() {
        #expect(reminders([dose()], medications: []).isEmpty)
    }

    @Test func aDoseOfAnArchivedMedicationStillGetsItsReminder() {
        var archived = medication()
        archived.archivedAt = takenAt
        #expect(reminders([dose()], medications: [archived]).count == 1)
    }

    @Test func aDoseWithItsAfterReadingGetsNoReminder() throws {
        let reading = try entry(at: takenAt)
        #expect(reminders([dose(after: reading.id)], entries: [reading]).isEmpty)
    }

    @Test func aNewerDoseOfAnyMedicationTakesTheReminderOfTheEarlierOne() {
        let earlier = dose()
        let newer = dose(at: takenAt.addingTimeInterval(60), delay: nil)
        #expect(reminders([earlier, newer]).isEmpty)
    }

    @Test func theNewerDoseKeepsItsReminderWhenTheEarlierOneLosesIt() {
        let earlier = dose()
        let newer = dose(at: takenAt.addingTimeInterval(60))
        let expected = CheckInReminder(doseID: newer.id, fireAt: newer.takenAt.addingTimeInterval(30 * 60))
        #expect(reminders([earlier, newer]) == [expected])
    }

    @Test func anEntryAtOrAfterTheDueMinuteTakesTheReminder() throws {
        #expect(try reminders([dose()], entries: [entry(at: due)]).isEmpty)
    }

    @Test func anEntryBeforeTheDueMinuteLeavesTheReminder() throws {
        #expect(try reminders([dose()], entries: [entry(at: due.addingTimeInterval(-60))]).count == 1)
    }

    @Test func aSavedAfterReadingTakesTheReminder() throws {
        let reading = try entry(at: takenAt.addingTimeInterval(5 * 60))
        #expect(reminders([dose()], entries: [reading]).count == 1)
        #expect(reminders([dose(after: reading.id)], entries: [reading]).isEmpty)
    }

    @Test func aNewerDoseOfAnotherMedicationWithCheckInOffTakesTheReminder() {
        let quellan = Medication(id: UUID(), name: "Quellan", takenAs: .asNeeded, createdAt: takenAt)
        var newer = dose(at: takenAt.addingTimeInterval(60), delay: nil)
        newer.medicationID = quellan.id
        #expect(reminders([dose()]).count == 1)
        #expect(reminders([dose(), newer], medications: [medication(), quellan]).isEmpty)
    }

    @Test func aDeletedDoseTakesItsReminder() {
        let kept = dose(at: takenAt.addingTimeInterval(-60 * 60))
        let deleted = dose()
        #expect(reminders([kept, deleted]).map(\.doseID) == [deleted.id])
        #expect(reminders([kept]).isEmpty)
    }

    @Test func noDosesGiveNoReminders() {
        #expect(reminders([]).isEmpty)
    }
}
