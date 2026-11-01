// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class MedicationsModel {
    private let store: MedicationStore
    private(set) var medications: [Medication] = []
    /// False until a read from the store has worked, so a store that was locked at launch is read before a write.
    private var isLoaded = false

    init(store: MedicationStore) {
        self.store = store
        reload()
    }

    var active: [Medication] {
        MedicationOrder.active(medications)
    }

    var archived: [Medication] {
        MedicationOrder.archived(medications)
    }

    var archivedCount: Int {
        medications.count { $0.archivedAt != nil }
    }

    /// Reads the store again. A failed read keeps the list as it was and leaves the next write to read first.
    func reload() {
        do {
            medications = try store.all()
            isLoaded = true
        } catch {
            isLoaded = false
        }
    }

    func add(_ medication: Medication) throws {
        try loadIfNeeded()
        try store.add(medication)
        medications.append(medication)
    }

    func archive(id: UUID) throws {
        try loadIfNeeded()
        let date = Date.now
        try store.archive(id: id, at: date)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = date
    }

    func update(_ medication: Medication) throws {
        try loadIfNeeded()
        try store.update(medication)
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[index] = medication
    }

    func restore(id: UUID) throws {
        try loadIfNeeded()
        try store.restore(id: id)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = nil
    }

    private func loadIfNeeded() throws {
        guard !isLoaded else { return }
        medications = try store.all()
        isLoaded = true
    }
}
