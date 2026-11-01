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
        let dose = try Dose(id: UUID(), medicationID: zorblex.id, takenAt: date, painBefore: #require(Severity(4)))
        try store.logDose(dose)
        #expect(try store.doses() == [dose])
        #expect(inner.doseContents == [dose])
    }

    @Test func aDoseWriteWhileLockedNeverReachesTheStore() throws {
        let zorblex = medication("Zorblex")
        let inner = FakeMedicationStore([zorblex])
        let store = DeferredMedicationStore {
            throw Locked()
        }
        let dose = try Dose(id: UUID(), medicationID: zorblex.id, takenAt: date, painBefore: #require(Severity(4)))
        #expect(throws: MedicationStoreError.unavailable) {
            try store.logDose(dose)
        }
        #expect(inner.doseContents.isEmpty)
    }
}
