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

    @Test func aReloadThatKeepsRetryingLoadsOnceTheStoreOpens() async throws {
        let inner = FakeMedicationStore([medication("Zorblex")])
        inner.readFailure = true
        let model = MedicationsModel(store: inner)
        let retrying = Task { await model.reloadUntilLoaded(every: .milliseconds(5), attempts: 1000) }
        try await Task.sleep(for: .milliseconds(30))
        #expect(!model.isLoaded)
        inner.readFailure = false
        await retrying.value
        #expect(model.isLoaded)
        #expect(model.medications.map(\.name) == ["Zorblex"])
    }

    @Test func aReloadGivesUpAfterItsAttemptsOnAStoreThatStaysClosed() async {
        let inner = FakeMedicationStore([medication("Zorblex")])
        inner.readFailure = true
        let model = MedicationsModel(store: inner)
        await model.reloadUntilLoaded(every: .milliseconds(1), attempts: 3)
        #expect(!model.isLoaded)
    }

    @Test func aLoadedModelIsNotReadAgain() async {
        let inner = FakeMedicationStore([medication("Zorblex")])
        let model = MedicationsModel(store: inner)
        inner.readFailure = true
        await model.reloadUntilLoaded(every: .milliseconds(1), attempts: 3)
        #expect(model.isLoaded)
        #expect(model.medications.map(\.name) == ["Zorblex"])
    }
}
