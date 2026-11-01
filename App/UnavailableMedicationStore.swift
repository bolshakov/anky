// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// Stands in when the store cannot open at launch, so the app still starts. Every call throws, and the file is left
/// alone.
@MainActor final class UnavailableMedicationStore: MedicationStore {
    func all() throws -> [Medication] {
        throw MedicationStoreError.unavailable
    }

    func add(_: Medication) throws {
        throw MedicationStoreError.unavailable
    }

    func archive(id _: UUID, at _: Date) throws {
        throw MedicationStoreError.unavailable
    }

    func update(_: Medication) throws {
        throw MedicationStoreError.unavailable
    }

    func restore(id _: UUID) throws {
        throw MedicationStoreError.unavailable
    }
}
