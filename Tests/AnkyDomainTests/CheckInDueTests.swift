// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInDueTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333)
    private let medicationID = UUID()

    private func medication(archived: Bool = false) -> Medication {
        var zorblex = Medication(id: medicationID, name: "Zorblex", takenAs: .asNeeded, createdAt: takenAt)
        zorblex.archivedAt = archived ? takenAt : nil
        return zorblex
    }

    private func dose(
        at time: Date? = nil, delay: CheckInDelay? = .thirtyMinutes, before: UUID? = nil, after: UUID? = nil
    ) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medicationID, takenAt: time ?? takenAt, beforeReadingID: before)
        dose.checkInAfter = delay
        dose.afterReadingID = after
        return dose
    }

    private func entry(id: UUID = UUID(), at date: Date) throws -> Entry {
        try Entry(id: id, kind: .pain, severity: #require(Severity(6)), date: date, note: nil, places: [])
    }

    private func waits(_ dose: Dose, medication: Medication? = nil, now: Date, entries: [Entry] = []) -> Bool {
        CheckInDue.isWaiting(
            dose,
            medication: medication ?? self.medication(),
            readings: DoseReadings(dose, in: entries),
            now: now
        )
    }

    @Test func aDoseWaitsFromTheMomentItsDelayHasPassed() {
        let due = takenAt.addingTimeInterval(30 * 60)
        #expect(waits(dose(), now: due))
        #expect(!waits(dose(), now: due.addingTimeInterval(-1)))
    }

    @Test func aDoseWithCheckInOffNeverWaits() {
        #expect(!waits(dose(delay: nil), now: takenAt.addingTimeInterval(24 * 60 * 60)))
    }

    @Test func aDoseWithNoMedicationNeverWaits() {
        #expect(!CheckInDue.isWaiting(dose(), medication: nil, readings: DoseReadings(dose(), in: []),
                                      now: takenAt.addingTimeInterval(3600)))
    }

    @Test func anArchivedMedicationsDoseNeverWaits() {
        #expect(!waits(dose(), medication: medication(archived: true), now: takenAt.addingTimeInterval(3600)))
    }

    @Test func aDoseWithItsAfterReadingIsNotWaiting() throws {
        let reading = try entry(at: takenAt)
        let checkedIn = dose(after: reading.id)
        #expect(!waits(checkedIn, now: takenAt.addingTimeInterval(3600), entries: [reading]))
    }

    /// The after-reading id points at an entry that was deleted, so the dose reads no after-reading and waits again.
    @Test func aDoseWhoseAfterEntryWasDeletedWaitsAgain() {
        let checkedIn = dose(after: UUID())
        #expect(waits(checkedIn, now: takenAt.addingTimeInterval(3600)))
    }

    @Test func theDelayIsTheDosesOwnNotTheMedicationsSavedDelay() {
        var saved = medication()
        saved.checkInAfter = .fourHours
        let shortDelay = dose(delay: .thirtyMinutes)
        #expect(waits(shortDelay, medication: saved, now: takenAt.addingTimeInterval(30 * 60)))
    }

    @Test func theWaitingListIsOldestFirstAndHoldsOnlyTheWaitingDoses() {
        let later = dose(at: takenAt.addingTimeInterval(600))
        let earlier = dose(at: takenAt)
        let notDue = dose(at: takenAt.addingTimeInterval(3600), delay: .fourHours)
        let now = takenAt.addingTimeInterval(3600)
        let result = CheckInDue.waiting(
            doses: [later, notDue, earlier],
            medications: [medication()],
            entries: [],
            now: now
        )
        #expect(result.map(\.id) == [earlier.id, later.id])
    }

    @Test func theWaitingListIsEmptyWithNoMedicationForTheDose() {
        let result = CheckInDue.waiting(doses: [dose()], medications: [], entries: [],
                                        now: takenAt.addingTimeInterval(3600))
        #expect(result.isEmpty)
    }

    /// The Today and History screens use this to wake at the next moment a row changes, without a tap.
    @Test func theNextDueIsTheEarliestDueMomentStillAhead() {
        let soon = dose(at: takenAt, delay: .thirtyMinutes)
        let later = dose(at: takenAt.addingTimeInterval(600), delay: .oneHour)
        let now = takenAt.addingTimeInterval(10 * 60)
        let next = CheckInDue.nextDue(doses: [later, soon], medications: [medication()], entries: [], after: now)
        #expect(next == takenAt.addingTimeInterval(30 * 60))
    }

    @Test func theNextDueSkipsMomentsThatHavePassed() {
        let passed = dose(at: takenAt, delay: .thirtyMinutes)
        let ahead = dose(at: takenAt, delay: .fourHours)
        let now = takenAt.addingTimeInterval(60 * 60)
        let next = CheckInDue.nextDue(doses: [passed, ahead], medications: [medication()], entries: [], after: now)
        #expect(next == takenAt.addingTimeInterval(4 * 60 * 60))
    }

    @Test func theNextDueIsNilWhenNoDoseWillWait() {
        let next = CheckInDue.nextDue(
            doses: [dose(delay: nil)],
            medications: [medication()],
            entries: [],
            after: takenAt
        )
        #expect(next == nil)
    }
}
