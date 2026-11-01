// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationOrderTests {
    private func medication(_ name: String, createdAt seconds: TimeInterval, archived: Bool = false) -> Medication {
        var medication = Medication(
            id: UUID(),
            name: name,
            takenAs: .asNeeded,
            createdAt: Date(timeIntervalSince1970: seconds)
        )
        if archived {
            medication.archivedAt = Date(timeIntervalSince1970: seconds + 1)
        }
        return medication
    }

    @Test func activeMedicationsAreOrderedByCreatedTimeOldestFirst() {
        let quibbanol = medication("Quibbanol", createdAt: 300)
        let zorblex = medication("Zorblex", createdAt: 100)
        let cyrillic = medication("Зорблекс", createdAt: 200)
        let ordered = MedicationOrder.active([quibbanol, zorblex, cyrillic])
        #expect(ordered.map(\.id) == [zorblex.id, cyrillic.id, quibbanol.id])
    }

    @Test func archivedMedicationsAreLeftOut() {
        let zorblex = medication("Zorblex", createdAt: 100)
        let quibbanol = medication("Quibbanol", createdAt: 200, archived: true)
        #expect(MedicationOrder.active([zorblex, quibbanol]).map(\.id) == [zorblex.id])
    }

    @Test func noMedicationsGivesAnEmptyList() {
        #expect(MedicationOrder.active([]).isEmpty)
    }

    private func archivedMedication(_ name: String, archivedAt seconds: TimeInterval) -> Medication {
        var archived = medication(name, createdAt: 100)
        archived.archivedAt = Date(timeIntervalSince1970: seconds)
        return archived
    }

    @Test func archivedMedicationsAreOrderedByArchivedTimeNewestFirst() {
        let quibbanol = archivedMedication("Quibbanol", archivedAt: 200)
        let zorblex = archivedMedication("Zorblex", archivedAt: 400)
        let fennimax = archivedMedication("Fennimax", archivedAt: 300)
        let ordered = MedicationOrder.archived([quibbanol, zorblex, fennimax])
        #expect(ordered.map(\.id) == [zorblex.id, fennimax.id, quibbanol.id])
    }

    @Test func activeMedicationsAreLeftOutOfArchived() {
        let zorblex = medication("Zorblex", createdAt: 100)
        let quibbanol = archivedMedication("Quibbanol", archivedAt: 200)
        #expect(MedicationOrder.archived([zorblex, quibbanol]).map(\.id) == [quibbanol.id])
    }

    @Test func noArchivedMedicationGivesAnEmptyList() {
        #expect(MedicationOrder.archived([medication("Zorblex", createdAt: 100)]).isEmpty)
    }

    @Test func aRestoredMedicationReturnsToItsCreatedPositionInTheActiveList() {
        let zorblex = medication("Zorblex", createdAt: 100)
        var quibbanol = medication("Quibbanol", createdAt: 200)
        let fennimax = medication("Fennimax", createdAt: 300)
        quibbanol.archivedAt = Date(timeIntervalSince1970: 400)
        #expect(MedicationOrder.active([fennimax, quibbanol, zorblex]).map(\.id) == [zorblex.id, fennimax.id])

        quibbanol.archivedAt = nil
        #expect(
            MedicationOrder.active([fennimax, quibbanol, zorblex]).map(\.id) == [zorblex.id, quibbanol.id, fennimax.id]
        )
    }
}
