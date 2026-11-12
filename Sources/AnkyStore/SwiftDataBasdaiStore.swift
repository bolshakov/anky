// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@MainActor public final class SwiftDataBasdaiStore: BasdaiStore {
    private let container: ModelContainer
    private let context: ModelContext
    private let beforeSave: @MainActor () throws -> Void

    public convenience init(url: URL, beforeSave: @escaping @MainActor () throws -> Void = {}) throws {
        let container = try ModelContainer(
            for: BasdaiRecord.self,
            configurations: ModelConfiguration(url: url)
        )
        self.init(container: container, beforeSave: beforeSave)
    }

    public static func inMemory(
        beforeSave: @escaping @MainActor () throws -> Void = {}
    ) throws -> SwiftDataBasdaiStore {
        let container = try ModelContainer(
            for: BasdaiRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataBasdaiStore(container: container, beforeSave: beforeSave)
    }

    private init(container: ModelContainer, beforeSave: @escaping @MainActor () throws -> Void) {
        self.container = container
        self.beforeSave = beforeSave
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    public func all() throws -> [BasdaiResult] {
        do {
            let descriptor = FetchDescriptor<BasdaiRecord>(
                sortBy: [SortDescriptor(\.date), SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { try $0.result() }
        } catch {
            throw BasdaiStoreError.unreadable
        }
    }

    public func add(_ result: BasdaiResult) throws {
        try context.insert(BasdaiRecord(result))
        try commit()
    }

    public func remove(id: UUID) throws {
        let descriptor = FetchDescriptor<BasdaiRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try? context.fetch(descriptor).first else {
            throw BasdaiStoreError.notSaved
        }
        context.delete(record)
        try commit()
    }

    public func removeAll() throws {
        let records: [BasdaiRecord]
        do {
            records = try context.fetch(FetchDescriptor<BasdaiRecord>())
        } catch {
            throw BasdaiStoreError.notSaved
        }
        guard !records.isEmpty else { return }
        records.forEach { context.delete($0) }
        try commit()
    }

    /// A failed commit discards every change made since the last one, so a retry starts from the stored state.
    private func commit() throws {
        do {
            try beforeSave()
            try context.save()
        } catch {
            context.rollback()
            throw BasdaiStoreError.notSaved
        }
    }
}
