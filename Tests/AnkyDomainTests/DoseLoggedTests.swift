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
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [earlier, latest],
            loggedAt: takenAt
        )
        #expect(dose.beforeReadingID == latest.id)
    }

    @Test func anEntryAMinuteOlderThanTheWindowIsNotPointedAt() throws {
        let tooOld = try entry(at: takenAt.addingTimeInterval(-ReadingWindow.length - 60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [tooOld],
            loggedAt: takenAt
        )
        #expect(dose.beforeReadingID == nil)
    }

    @Test func anEntryLoggedAfterTheDoseIsNotPointedAt() throws {
        let later = try entry(at: takenAt.addingTimeInterval(60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [later], loggedAt: takenAt
        )
        #expect(dose.beforeReadingID == nil)
    }

    @Test func aManualPickIsTheReadingEvenWhenANewerEntryIsInTheWindow() throws {
        let picked = try entry(at: takenAt.addingTimeInterval(-3600))
        let newer = try entry(at: takenAt.addingTimeInterval(-60))
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt,
            entries: [picked, newer], manualReadingID: picked.id, loggedAt: takenAt
        )
        #expect(dose.beforeReadingID == picked.id)
    }

    @Test func aFatigueEntryInTheWindowCanBeTheReading() throws {
        let fatigue = try Entry(
            id: UUID(), kind: .fatigue, severity: #require(Severity(6)),
            date: takenAt.addingTimeInterval(-60), note: nil, places: []
        )
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [fatigue],
            loggedAt: takenAt
        )
        #expect(dose.beforeReadingID == fatigue.id)
    }

    @Test func aDoseKeepsItsIdTimeAndMedicationAndTakesTheMedicationsCheckInDelay() {
        let id = UUID()
        let zorblex = medication(checkInAfter: .oneHour)
        let dose = Dose.logged(id: id, medication: zorblex, takenAt: takenAt, entries: [], loggedAt: takenAt)
        #expect(dose.id == id)
        #expect(dose.medicationID == zorblex.id)
        #expect(dose.takenAt == takenAt)
        #expect(dose.checkInAfter == .oneHour)
        #expect(dose.beforeReadingID == nil)
        #expect(dose.afterReadingID == nil)
    }

    @Test func aDoseKeepsTheMomentItWasLogged() {
        let loggedAt = takenAt.addingTimeInterval(90)
        let dose = Dose.logged(
            id: UUID(), medication: medication(checkInAfter: nil), takenAt: takenAt, entries: [], loggedAt: loggedAt
        )
        #expect(dose.loggedAt == loggedAt)
    }
}
