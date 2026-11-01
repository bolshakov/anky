// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@MainActor public final class SwiftDataMedicationStore: MedicationStore {
    private let container: ModelContainer
    private let context: ModelContext
    private let beforeSave: @MainActor () throws -> Void

    public convenience init(url: URL, beforeSave: @escaping @MainActor () throws -> Void = {}) throws {
        let container = try ModelContainer(
            for: MedicationRecord.self,
            configurations: ModelConfiguration(url: url)
        )
        self.init(container: container, beforeSave: beforeSave)
    }

    public static func inMemory(
        beforeSave: @escaping @MainActor () throws -> Void = {}
    ) throws -> SwiftDataMedicationStore {
        let container = try ModelContainer(
            for: MedicationRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataMedicationStore(container: container, beforeSave: beforeSave)
    }

    private init(container: ModelContainer, beforeSave: @escaping @MainActor () throws -> Void) {
        self.container = container
        self.beforeSave = beforeSave
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    public func all() throws -> [Medication] {
        do {
            let descriptor = FetchDescriptor<MedicationRecord>(sortBy: [SortDescriptor(\.createdAt)])
            return try context.fetch(descriptor).map { try $0.medication() }
        } catch {
            throw MedicationStoreError.unreadable
        }
    }

    public func add(_ medication: Medication) throws {
        context.insert(MedicationRecord(medication))
        try commit()
    }

    public func archive(id: UUID, at date: Date) throws {
        try record(id: id).archivedAt = date
        try commit()
    }

    public func update(_ medication: Medication) throws {
        let record = try record(id: medication.id)
        record.assign(medication)
        try commit()
    }

    public func restore(id: UUID) throws {
        try record(id: id).archivedAt = nil
        try commit()
    }

    private func record(id: UUID) throws -> MedicationRecord {
        let descriptor = FetchDescriptor<MedicationRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try? context.fetch(descriptor).first else {
            throw MedicationStoreError.notSaved
        }
        return record
    }

    /// A failed commit discards every change made since the last one, so a retry starts from the stored state.
    private func commit() throws {
        do {
            try beforeSave()
            try context.save()
        } catch {
            context.rollback()
            throw MedicationStoreError.notSaved
        }
    }
}
