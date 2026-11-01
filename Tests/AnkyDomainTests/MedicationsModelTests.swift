// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import Foundation
import Testing

@MainActor struct MedicationsModelTests {
    private func medication(_ name: String) -> Medication {
        Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: .now)
    }

    enum Write: CaseIterable {
        case add, archive, update, restore

        @MainActor func run(on model: MedicationsModel, zorblex: Medication) throws {
            switch self {
            case .add:
                try model.add(Medication(id: UUID(), name: "Quibbanol", takenAs: .asNeeded, createdAt: .now))
            case .archive: try model.archive(id: zorblex.id)
            case .update:
                var renamed = zorblex
                renamed.name = "Zorblex XR"
                try model.update(renamed)
            case .restore: try model.restore(id: zorblex.id)
            }
        }
    }

    @Test(arguments: Write.allCases)
    func aWriteAfterALockedLaunchReadsTheStoredRowsFirst(_ write: Write) throws {
        let zorblex = medication("Zorblex")
        var locked = true
        let store = DeferredMedicationStore {
            if locked {
                throw MedicationStoreError.unavailable
            }
            return FakeMedicationStore([zorblex])
        }
        let model = MedicationsModel(store: store)
        #expect(model.medications.isEmpty)
        locked = false
        try write.run(on: model, zorblex: zorblex)
        #expect(model.medications.count == (write == .add ? 2 : 1))
    }

    @Test func aFailedReloadKeepsTheListAndTheNextWriteReadsFirst() throws {
        let inner = FakeMedicationStore([medication("Zorblex")])
        let model = MedicationsModel(store: inner)
        inner.readFailure = true
        model.reload()
        #expect(model.medications.map(\.name) == ["Zorblex"])
        inner.readFailure = false
        try inner.add(medication("Quibbanol"))
        try model.add(medication("Fennimax"))
        #expect(model.medications.map(\.name) == ["Zorblex", "Quibbanol", "Fennimax"])
    }

    @Test func aWriteWhileTheListIsUnreadNeverReachesTheStore() throws {
        let inner = FakeMedicationStore([medication("Zorblex")])
        inner.readFailure = true
        let model = MedicationsModel(store: inner)
        #expect(throws: MedicationStoreError.unreadable) { try model.add(medication("Quibbanol")) }
        #expect(inner.addCalls.isEmpty)
        inner.readFailure = false
        try model.add(medication("Quibbanol"))
        #expect(model.medications.map(\.name) == ["Zorblex", "Quibbanol"])
    }

    @Test func aLoadedListSavesWhileReadsFail() throws {
        let inner = FakeMedicationStore([medication("Zorblex")])
        let model = MedicationsModel(store: inner)
        inner.readFailure = true
        try model.add(medication("Quibbanol"))
        #expect(model.medications.map(\.name) == ["Zorblex", "Quibbanol"])
    }

    @Test(arguments: Write.allCases)
    func aFailedWriteLeavesTheListAsItWas(_ write: Write) {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true
        #expect(throws: MedicationStoreError.notSaved) { try write.run(on: model, zorblex: zorblex) }
        #expect(model.medications == [zorblex])
    }

    private func dose(for medication: Medication, checkInAfter: CheckInDelay? = nil) throws -> Dose {
        var dose = try Dose(
            id: UUID(),
            medicationID: medication.id,
            takenAt: .now,
            painBefore: #require(Severity(4))
        )
        dose.checkInAfter = checkInAfter
        return dose
    }

    @Test func logDoseAddsTheDoseAndTheSavedDelayToTheModel() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        let dose = try dose(for: zorblex, checkInAfter: .twoHours)
        try model.logDose(dose)
        #expect(model.doses == [dose])
        #expect(model.medications.first?.checkInAfter == .twoHours)
        #expect(try inner.doses() == [dose])
    }

    @Test func aFailedLogLeavesTheModelAsItWas() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true
        #expect(throws: MedicationStoreError.notSaved) {
            try model.logDose(dose(for: zorblex, checkInAfter: .oneHour))
        }
        #expect(model.doses.isEmpty)
        #expect(model.medications == [zorblex])
        #expect(inner.doseContents.isEmpty)
    }

    @Test func aDoseWithNoDelayClearsTheSavedDelay() throws {
        var zorblex = medication("Zorblex")
        zorblex.checkInAfter = .oneHour
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        try model.logDose(dose(for: zorblex, checkInAfter: nil))
        #expect(model.medications.first?.checkInAfter == nil)
        #expect(try inner.all().first?.checkInAfter == nil)
    }

    @Test func aFailedLogKeepsTheSavedDelay() throws {
        var zorblex = medication("Zorblex")
        zorblex.checkInAfter = .oneHour
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true
        #expect(throws: MedicationStoreError.notSaved) {
            try model.logDose(dose(for: zorblex, checkInAfter: .fourHours))
        }
        #expect(model.medications == [zorblex])
        #expect(try inner.all() == [zorblex])
    }

    @Test func reloadReadsTheDosesWithTheMedications() throws {
        let zorblex = medication("Zorblex")
        let stored = try dose(for: zorblex)
        let inner = FakeMedicationStore([zorblex], doses: [stored])
        let model = MedicationsModel(store: inner)
        #expect(model.doses == [stored])
    }

    @Test func aFailedDoseReadKeepsTheMedicationsAndTheNextWriteReadsFirst() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        inner.readFailure = true
        model.reload()
        #expect(model.medications == [zorblex])
        #expect(model.doses.isEmpty)
        inner.readFailure = false
        try model.logDose(dose(for: zorblex))
        #expect(model.doses.count == 1)
    }
}
