// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import Foundation
import Testing

@MainActor struct MedicationsModelEraseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func medication(_ name: String, archived: Bool = false) -> Medication {
        var medication = Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: now)
        medication.checkInAfter = .thirtyMinutes
        medication.archivedAt = archived ? now : nil
        return medication
    }

    private func dose(for medication: Medication, minutes: Double = -5) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medication.id, takenAt: now.addingTimeInterval(minutes * 60))
        dose.checkInAfter = .thirtyMinutes
        return dose
    }

    @Test func removeAllEmptiesBothListsAndTheStore() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex, medication("Fennimax", archived: true)], doses: [dose(for: zorblex)])
        let model = MedicationsModel(store: inner)

        try model.removeAll()

        #expect(model.medications.isEmpty)
        #expect(model.doses.isEmpty)
        #expect(try inner.all().isEmpty)
        #expect(try inner.doses().isEmpty)
    }

    @Test func aRefusedRemoveAllLeavesBothListsAsTheyWere() throws {
        let zorblex = medication("Zorblex")
        let taken = dose(for: zorblex)
        let inner = FakeMedicationStore([zorblex], doses: [taken])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true

        #expect(throws: MedicationStoreError.notSaved) { try model.removeAll() }

        #expect(model.medications == [zorblex])
        #expect(model.doses == [taken])
        #expect(inner.contents == [zorblex])
        #expect(inner.doseContents == [taken])
    }

    @Test func removeAllOnAnEmptyStoreSucceeds() throws {
        let model = MedicationsModel(store: FakeMedicationStore())

        try model.removeAll()

        #expect(model.medications.isEmpty)
        #expect(model.doses.isEmpty)
    }

    @Test func aRetryAfterARefusalFinishesTheErase() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex], doses: [dose(for: zorblex)])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true
        #expect(throws: MedicationStoreError.notSaved) { try model.removeAll() }
        inner.writeFailure = false

        try model.removeAll()

        #expect(model.medications.isEmpty)
        #expect(model.doses.isEmpty)
    }

    @Test func removeAllAfterALockedLaunchErasesTheStoredRows() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex], doses: [dose(for: zorblex)])
        var locked = true
        let model = MedicationsModel(store: DeferredMedicationStore {
            if locked {
                throw MedicationStoreError.unavailable
            }
            return inner
        })
        locked = false

        try model.removeAll()

        #expect(inner.contents.isEmpty)
        #expect(inner.doseContents.isEmpty)
    }

    @Test func afterAnEraseLogDoseHasNoMedicationToOfferAndNoManageLink() throws {
        let zorblex = medication("Zorblex")
        let model = MedicationsModel(store: FakeMedicationStore(
            [zorblex, medication("Fennimax", archived: true)],
            doses: [dose(for: zorblex)]
        ))

        try model.removeAll()

        #expect(model.active.isEmpty)
        #expect(model.medications.isEmpty)
    }

    @Test func afterAnEraseTheReconcileCancelsTheErasedDosesPendingReminder() throws {
        let zorblex = medication("Zorblex")
        let taken = dose(for: zorblex)
        let model = MedicationsModel(store: FakeMedicationStore([zorblex], doses: [taken]))
        let pending = CheckInDue.reminders(doses: model.doses, medications: model.medications, entries: [], now: now)
        #expect(pending.map(\.doseID) == [taken.id])

        try model.removeAll()

        let wanted = CheckInDue.reminders(doses: model.doses, medications: model.medications, entries: [], now: now)
        #expect(CheckInReminder.toCancel(pending: pending.map(\.doseID), wanted: wanted) == [taken.id])
    }
}
