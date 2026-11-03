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

    private func dose(for medication: Medication, checkInAfter: CheckInDelay? = nil) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medication.id, takenAt: .now)
        dose.checkInAfter = checkInAfter
        return dose
    }

    @Test func logDoseAddsTheDoseAndTheSavedDelayToTheModel() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        let taken = dose(for: zorblex, checkInAfter: .twoHours)
        try model.logDose(taken)
        #expect(model.doses == [taken])
        #expect(model.medications.first?.checkInAfter == .twoHours)
        #expect(try inner.doses() == [taken])
    }

    @Test(arguments: [CheckInDelay?.none, .fourHours])
    func logDoseWritesTheDosesDelayOverTheSavedOne(_ delay: CheckInDelay?) throws {
        var zorblex = medication("Zorblex")
        zorblex.checkInAfter = .oneHour
        let inner = FakeMedicationStore([zorblex])
        let model = MedicationsModel(store: inner)
        try model.logDose(dose(for: zorblex, checkInAfter: delay))
        #expect(model.medications.first?.checkInAfter == delay)
        #expect(try inner.all().first?.checkInAfter == delay)
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

    @Test func reloadReadsTheDosesWithTheMedications() {
        let zorblex = medication("Zorblex")
        let stored = dose(for: zorblex)
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

    private func dose(for medication: Medication, at takenAt: Date) -> Dose {
        Dose(id: UUID(), medicationID: medication.id, takenAt: takenAt)
    }

    @Test func replaceDoseUpdatesTheDoseInTheModel() throws {
        let zorblex = medication("Zorblex")
        let original = dose(for: zorblex, at: .now)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        let model = MedicationsModel(store: inner)
        var edited = original
        edited.takenAt = original.takenAt.addingTimeInterval(3600)
        try model.replaceDose(edited)
        #expect(model.doses == [edited])
        #expect(try inner.doses() == [edited])
    }

    @Test func aReplacedDoseListsAtItsNewTime() throws {
        let zorblex = medication("Zorblex")
        let calendar = Calendar.current
        let nine = try #require(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now))
        let ten = try #require(calendar.date(bySettingHour: 10, minute: 0, second: 0, of: .now))
        let eleven = try #require(calendar.date(bySettingHour: 11, minute: 0, second: 0, of: .now))
        let moved = dose(for: zorblex, at: nine)
        let other = dose(for: zorblex, at: ten)
        let inner = FakeMedicationStore([zorblex], doses: [moved, other])
        let model = MedicationsModel(store: inner)
        #expect(listed(model, on: nine, calendar: calendar) == [other.id, moved.id])

        var edited = moved
        edited.takenAt = eleven
        try model.replaceDose(edited)
        #expect(listed(model, on: nine, calendar: calendar) == [edited.id, other.id])
    }

    @Test func aRefusedReplaceLeavesTheModelAsItWas() throws {
        let zorblex = medication("Zorblex")
        let original = dose(for: zorblex, at: .now)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        let model = MedicationsModel(store: inner)
        inner.writeFailure = true
        var edited = original
        edited.takenAt = original.takenAt.addingTimeInterval(60)
        #expect(throws: MedicationStoreError.notSaved) {
            try model.replaceDose(edited)
        }
        #expect(model.doses == [original])
        #expect(inner.doseContents == [original])
    }

    private func listed(_ model: MedicationsModel, on day: Date, calendar: Calendar) -> [UUID] {
        TodayList.items(entries: [], doses: model.doses, on: day, calendar: calendar).map(\.id)
    }
}
