// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct DeferredMedicationStoreTests {
    private struct Locked: Error {}

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func medication(_ name: String) -> Medication {
        Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: date)
    }

    @Test func aStoreThatCannotOpenThrowsUnavailableAndOpensOnALaterCall() throws {
        let inner = FakeMedicationStore([medication("Zorblex")])
        var locked = true
        var attempts = 0
        let store = DeferredMedicationStore {
            attempts += 1
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: MedicationStoreError.unavailable) { try store.all() }
        locked = false
        #expect(try store.all().map(\.name) == ["Zorblex"])
        #expect(attempts == 2)
    }

    @Test func anOpenedStoreIsNotOpenedAgain() throws {
        var attempts = 0
        let store = DeferredMedicationStore {
            attempts += 1
            return FakeMedicationStore()
        }
        _ = try store.all()
        try store.add(medication("Quibbanol"))
        _ = try store.all()
        #expect(attempts == 1)
    }

    @Test func aWriteWhileLockedNeverReachesTheStoreAndSucceedsOnceOpened() throws {
        let inner = FakeMedicationStore()
        var locked = true
        let store = DeferredMedicationStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: MedicationStoreError.unavailable) {
            try store.add(medication("Fennimax"))
        }
        #expect(inner.addCalls.isEmpty)
        locked = false
        try store.add(medication("Fennimax"))
        #expect(inner.contents.map(\.name) == ["Fennimax"])
    }

    @Test func doseCallsForwardThroughTheOpenedStore() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let store = DeferredMedicationStore { inner }
        let dose = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        try store.logDose(dose)
        #expect(try store.doses() == [dose])
        #expect(inner.doseContents == [dose])
    }

    @Test func aDoseReplaceForwardsThroughTheOpenedStore() throws {
        let zorblex = medication("Zorblex")
        let original = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        let store = DeferredMedicationStore { inner }
        var edited = original
        edited.takenAt = date.addingTimeInterval(60)
        try store.replaceDose(edited)
        #expect(inner.doseContents == [edited])
    }

    @Test func aDoseRemoveForwardsThroughTheOpenedStore() throws {
        let zorblex = medication("Zorblex")
        let original = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        let store = DeferredMedicationStore { inner }
        try store.removeDose(id: original.id)
        #expect(inner.doseContents.isEmpty)
    }

    @Test func removeAllForwardsThroughTheOpenedStore() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex], doses: [Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)])
        let store = DeferredMedicationStore { inner }
        try store.removeAll()
        #expect(inner.contents.isEmpty)
        #expect(inner.doseContents.isEmpty)
    }

    @Test func removeAllOnAStoreThatCannotOpenThrowsUnavailableAndChangesNothing() throws {
        let zorblex = medication("Zorblex")
        let original = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        var locked = true
        let store = DeferredMedicationStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: MedicationStoreError.unavailable) { try store.removeAll() }
        #expect(inner.contents == [zorblex])
        #expect(inner.doseContents == [original])
        locked = false
        try store.removeAll()
        #expect(inner.contents.isEmpty)
    }

    @Test func aDoseReplaceWhileLockedNeverReachesTheStore() throws {
        let zorblex = medication("Zorblex")
        let original = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        var locked = true
        let store = DeferredMedicationStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        var edited = original
        edited.takenAt = date.addingTimeInterval(60)
        #expect(throws: MedicationStoreError.unavailable) {
            try store.replaceDose(edited)
        }
        #expect(inner.doseContents == [original])
    }

    @Test func aDoseRemoveWhileLockedNeverReachesTheStore() throws {
        let zorblex = medication("Zorblex")
        let original = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        let inner = FakeMedicationStore([zorblex], doses: [original])
        let store = DeferredMedicationStore {
            throw Locked()
        }
        #expect(throws: MedicationStoreError.unavailable) {
            try store.removeDose(id: original.id)
        }
        #expect(inner.doseContents == [original])
    }

    @Test func aDoseWriteWhileLockedNeverReachesTheStore() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let store = DeferredMedicationStore {
            throw Locked()
        }
        let dose = Dose(id: UUID(), medicationID: zorblex.id, takenAt: date)
        #expect(throws: MedicationStoreError.unavailable) {
            try store.logDose(dose)
        }
        #expect(inner.doseContents.isEmpty)
    }
}
