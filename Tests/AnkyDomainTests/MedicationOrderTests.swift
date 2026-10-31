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
}
