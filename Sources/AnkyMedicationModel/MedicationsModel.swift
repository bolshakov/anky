// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable public final class MedicationsModel {
    private let store: MedicationStore
    public private(set) var medications: [Medication] = []
    public private(set) var doses: [Dose] = []
    /// False until a read from the store has worked, so a store that was locked at launch is read before a write.
    private var isLoaded = false

    public init(store: MedicationStore) {
        self.store = store
        reload()
    }

    public var active: [Medication] {
        MedicationOrder.active(medications)
    }

    public var archived: [Medication] {
        MedicationOrder.archived(medications)
    }

    public var archivedCount: Int {
        medications.count { $0.archivedAt != nil }
    }

    /// Reads the store again. A failed read keeps the lists as they were and leaves the next write to read first.
    public func reload() {
        do {
            try readAll()
        } catch {
            isLoaded = false
        }
    }

    public func add(_ medication: Medication) throws {
        try loadIfNeeded()
        try store.add(medication)
        medications.append(medication)
    }

    public func archive(id: UUID) throws {
        try loadIfNeeded()
        let date = Date.now
        try store.archive(id: id, at: date)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = date
    }

    public func update(_ medication: Medication) throws {
        try loadIfNeeded()
        try store.update(medication)
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[index] = medication
    }

    public func restore(id: UUID) throws {
        try loadIfNeeded()
        try store.restore(id: id)
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        medications[index].archivedAt = nil
    }

    public func logDose(_ dose: Dose) throws {
        try loadIfNeeded()
        try store.logDose(dose)
        doses.append(dose)
        guard let index = medications.firstIndex(where: { $0.id == dose.medicationID }) else { return }
        medications[index].checkInAfter = dose.checkInAfter
    }

    /// Reads both lists before it changes either, so a failed read of doses leaves the medications as they were.
    private func readAll() throws {
        let medications = try store.all()
        let doses = try store.doses()
        self.medications = medications
        self.doses = doses
        isLoaded = true
    }

    private func loadIfNeeded() throws {
        guard !isLoaded else { return }
        try readAll()
    }
}
