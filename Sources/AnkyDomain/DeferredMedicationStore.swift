// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Opens its store on the first call, and on each later call until one open works. A store that cannot open throws
/// `unavailable` and leaves whatever it guards as it is, so a phone that is locked at launch can open it later.
@MainActor public final class DeferredMedicationStore: MedicationStore {
    private let open: @MainActor () throws -> MedicationStore
    private var opened: MedicationStore?

    public init(open: @escaping @MainActor () throws -> MedicationStore) {
        self.open = open
    }

    public func all() throws -> [Medication] {
        try current().all()
    }

    public func add(_ medication: Medication) throws {
        try current().add(medication)
    }

    public func archive(id: UUID, at date: Date) throws {
        try current().archive(id: id, at: date)
    }

    public func update(_ medication: Medication) throws {
        try current().update(medication)
    }

    public func restore(id: UUID) throws {
        try current().restore(id: id)
    }

    private func current() throws -> MedicationStore {
        if let opened {
            return opened
        }
        do {
            let store = try open()
            opened = store
            return store
        } catch {
            throw MedicationStoreError.unavailable
        }
    }
}
