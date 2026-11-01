// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class MedicationsModel {
    private let store: MedicationStore
    private(set) var medications: [Medication]

    init(store: MedicationStore) {
        self.store = store
        medications = (try? store.all()) ?? []
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

    func add(_ medication: Medication) throws {
        try store.add(medication)
        medications.append(medication)
    }

    func archive(id: UUID) throws {
        let date = Date.now
        try store.archive(id: id, at: date)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = date
    }

    func update(_ medication: Medication) throws {
        try store.update(medication)
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[index] = medication
    }

    func restore(id: UUID) throws {
        try store.restore(id: id)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = nil
    }
}
