// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EditDoseMedicationsTests {
    private func make(_ name: String, created: TimeInterval, archived: TimeInterval? = nil) -> Medication {
        var medication = Medication(
            id: UUID(),
            name: name,
            takenAs: .asNeeded,
            createdAt: Date(timeIntervalSince1970: created)
        )
        medication.archivedAt = archived.map { Date(timeIntervalSince1970: $0) }
        return medication
    }

    private func dose(of medication: Medication) -> Dose {
        Dose(id: UUID(), medicationID: medication.id, takenAt: .now)
    }

    @Test func aRestoredDoseMedicationIsListedOnce() {
        let zorblex = make("Zorblex", created: 100)
        let quibbanol = make("Quibbanol", created: 200)
        let restored = make("Restored", created: 300)
        let choices = EditDoseMedications.choices(
            for: dose(of: restored),
            in: [zorblex, quibbanol, restored]
        )
        #expect(choices.map(\.id) == [zorblex.id, quibbanol.id, restored.id])
    }

    @Test func anArchivedDoseMedicationIsListedOnceInCreatedOrder() {
        let zorblex = make("Zorblex", created: 100)
        let archived = make("Archived", created: 50, archived: 150)
        let choices = EditDoseMedications.choices(for: dose(of: archived), in: [archived, zorblex])
        #expect(choices.map(\.id) == [archived.id, zorblex.id])
    }

    @Test func aNewerArchivedDoseMedicationIsListedInCreatedOrderToo() {
        let zorblex = make("Zorblex", created: 100)
        let archived = make("Archived", created: 200, archived: 250)
        let choices = EditDoseMedications.choices(for: dose(of: archived), in: [archived, zorblex])
        #expect(choices.map(\.id) == [zorblex.id, archived.id])
    }

    @Test func otherArchivedMedicationsAreLeftOut() {
        let zorblex = make("Zorblex", created: 100)
        let other = make("Other", created: 200, archived: 250)
        let doseMedication = make("Dose", created: 300)
        let choices = EditDoseMedications.choices(for: dose(of: doseMedication), in: [zorblex, other, doseMedication])
        #expect(choices.map(\.id) == [zorblex.id, doseMedication.id])
    }
}
