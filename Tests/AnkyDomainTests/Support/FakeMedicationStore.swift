// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A medication store held in memory. Tests read `addCalls` to see every add, refused ones included.
@MainActor final class FakeMedicationStore: MedicationStore {
    private(set) var contents: [Medication]
    private(set) var addCalls: [Medication] = []
    /// Set to make the next writes throw. Set back to false to let them succeed.
    var writeFailure = false

    init(_ medications: [Medication] = []) {
        contents = medications
    }

    func all() throws -> [Medication] {
        contents
    }

    func add(_ medication: Medication) throws {
        addCalls.append(medication)
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        contents.append(medication)
    }
}
