// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

/// Stands in when the store cannot open at launch, so the app still starts. Every call throws, and the file is left
/// alone.
@MainActor final class UnavailableMedicationStore: MedicationStore {
    func all() throws -> [Medication] {
        throw MedicationStoreError.unavailable
    }

    func add(_: Medication) throws {
        throw MedicationStoreError.unavailable
    }
}
