// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import Foundation
import Testing

@MainActor struct MedicationsModelLoadedTests {
    private func medication(_ name: String) -> Medication {
        Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: .now)
    }

    @Test func aStoreThatOpensAtLaunchIsLoaded() {
        #expect(MedicationsModel(store: FakeMedicationStore([medication("Zorblex")])).isLoaded)
    }

    @Test func aStoreThatFailsItsFirstReadIsNotLoadedUntilAReloadWorks() {
        let inner = FakeMedicationStore([medication("Zorblex")])
        inner.readFailure = true
        let model = MedicationsModel(store: inner)
        #expect(!model.isLoaded)
        #expect(model.medications.isEmpty)
        model.reload()
        #expect(!model.isLoaded)
        inner.readFailure = false
        model.reload()
        #expect(model.isLoaded)
        #expect(model.medications.map(\.name) == ["Zorblex"])
    }
}
