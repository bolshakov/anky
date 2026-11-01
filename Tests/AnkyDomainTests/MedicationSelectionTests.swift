// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationSelectionTests {
    private func medication(_ name: String, createdAt seconds: TimeInterval) -> Medication {
        Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: Date(timeIntervalSince1970: seconds))
    }

    @Test func aSelectedActiveMedicationStaysSelected() {
        let zorblex = medication("Zorblex", createdAt: 100)
        let quibbanol = medication("Quibbanol", createdAt: 200)
        #expect(MedicationSelection.kept(quibbanol.id, in: [zorblex, quibbanol]) == quibbanol.id)
    }

    @Test func aSelectionNoLongerActiveFallsToTheFirstActiveRow() {
        let zorblex = medication("Zorblex", createdAt: 100)
        let quibbanol = medication("Quibbanol", createdAt: 200)
        #expect(MedicationSelection.kept(quibbanol.id, in: [zorblex]) == zorblex.id)
    }

    @Test func noSelectionFallsToTheFirstActiveRow() {
        let zorblex = medication("Zorblex", createdAt: 100)
        let quibbanol = medication("Quibbanol", createdAt: 200)
        #expect(MedicationSelection.kept(nil, in: [zorblex, quibbanol]) == zorblex.id)
    }

    @Test func noActiveMedicationGivesNoSelection() {
        let quibbanol = medication("Quibbanol", createdAt: 200)
        #expect(MedicationSelection.kept(quibbanol.id, in: []) == nil)
        #expect(MedicationSelection.kept(nil, in: []) == nil)
    }
}
