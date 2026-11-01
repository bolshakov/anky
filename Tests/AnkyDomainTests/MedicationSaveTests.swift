// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct MedicationSaveTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft() -> MedicationDraft {
        var draft = MedicationDraft()
        draft.name = "Zorblex"
        return draft
    }

    @Test func aSecondSaveAfterASuccessWritesNothing() throws {
        let store = FakeMedicationStore()
        var save = MedicationSave(id: UUID())
        #expect(try save.save(draft(), at: date, add: store.add))
        #expect(try !save.save(draft(), at: date, add: store.add))
        #expect(store.addCalls.count == 1)
        #expect(save.isSaved)
    }

    @Test func aFailedWriteLeavesTheSaveOpenAndTheRetryUsesTheSameId() throws {
        let store = FakeMedicationStore()
        let id = UUID()
        var save = MedicationSave(id: id)
        store.writeFailure = true
        #expect(throws: MedicationStoreError.notSaved) {
            try save.save(draft(), at: date, add: store.add)
        }
        #expect(!save.isSaved)
        store.writeFailure = false
        #expect(try save.save(draft(), at: date, add: store.add))
        #expect(store.contents.map(\.id) == [id])
    }
}
