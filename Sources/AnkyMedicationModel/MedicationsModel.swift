// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable public final class MedicationsModel {
    private let store: MedicationStore
    public private(set) var medications: [Medication] = []
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

    /// Reads the store again. A failed read keeps the list as it was and leaves the next write to read first.
    public func reload() {
        do {
            medications = try store.all()
            isLoaded = true
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

    private func loadIfNeeded() throws {
        guard !isLoaded else { return }
        medications = try store.all()
        isLoaded = true
    }
}
