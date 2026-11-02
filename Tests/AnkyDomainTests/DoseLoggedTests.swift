// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseLoggedTests {
    private let takenAt = Date(timeIntervalSince1970: 1_800_000_000)

    private func medication(checkInAfter: CheckInDelay?) -> Medication {
        var medication = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: takenAt)
        medication.checkInAfter = checkInAfter
        return medication
    }

    private func entry(at date: Date) throws -> Entry {
        try Entry(
            id: UUID(), kind: .pain, severity: #require(Severity(4)), date: date, note: nil, places: []
        )
    }

    @Test func aDosePointsAtTheLatestEntryInTheWindowBeforeIt() throws {
        let earlier = try entry(at: takenAt.addingTimeInterval(-3600))
        let latest = try entry(at: takenAt.addingTimeInterval(-60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [earlier, latest]
        )
        #expect(dose.beforeReadingID == latest.id)
    }

    @Test func anEntryAMinuteOlderThanTheWindowIsNotPointedAt() throws {
        let tooOld = try entry(at: takenAt.addingTimeInterval(-ReadingWindow.length - 60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [tooOld]
        )
        #expect(dose.beforeReadingID == nil)
    }

    @Test func anEntryLoggedAfterTheDoseIsNotPointedAt() throws {
        let later = try entry(at: takenAt.addingTimeInterval(60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [later]
        )
        #expect(dose.beforeReadingID == nil)
    }

    @Test func aDoseKeepsItsIdTimeAndMedicationAndTakesTheMedicationsCheckInDelay() {
        let id = UUID()
        let zorblex = medication(checkInAfter: .oneHour)
        let dose = Dose.logged(id: id, medication: zorblex, takenAt: takenAt, entries: [])
        #expect(dose.id == id)
        #expect(dose.medicationID == zorblex.id)
        #expect(dose.takenAt == takenAt)
        #expect(dose.checkInAfter == .oneHour)
        #expect(dose.beforeReadingID == nil)
        #expect(dose.afterReadingID == nil)
    }
}
