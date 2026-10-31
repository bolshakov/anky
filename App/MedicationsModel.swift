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

    func add(_ medication: Medication) throws {
        try store.add(medication)
        medications.append(medication)
    }
}
