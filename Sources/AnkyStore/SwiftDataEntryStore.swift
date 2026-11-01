// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@MainActor public final class SwiftDataEntryStore: EntryStore {
    private let container: ModelContainer
    private let context: ModelContext
    private let beforeSave: @MainActor () throws -> Void

    public convenience init(url: URL, beforeSave: @escaping @MainActor () throws -> Void = {}) throws {
        let container = try ModelContainer(
            for: EntryRecord.self,
            configurations: ModelConfiguration(url: url)
        )
        self.init(container: container, beforeSave: beforeSave)
    }

    public static func inMemory(
        beforeSave: @escaping @MainActor () throws -> Void = {}
    ) throws -> SwiftDataEntryStore {
        let container = try ModelContainer(
            for: EntryRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataEntryStore(container: container, beforeSave: beforeSave)
    }

    private init(container: ModelContainer, beforeSave: @escaping @MainActor () throws -> Void) {
        self.container = container
        self.beforeSave = beforeSave
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    public func load() throws -> [Entry] {
        let descriptor = FetchDescriptor<EntryRecord>(sortBy: [SortDescriptor(\.position)])
        let records: [EntryRecord]
        do {
            records = try context.fetch(descriptor)
        } catch {
            throw EntryStoreError.unreadable
        }
        return try records.map { try $0.entry() }
    }

    public func add(_ entry: Entry) throws {
        guard try record(id: entry.id) == nil else { return }
        try context.insert(EntryRecord(entry, position: nextPosition()))
        try commit()
    }

    public func replace(_ entry: Entry) throws {
        guard let record = try record(id: entry.id) else { throw EntryStoreError.notSaved }
        record.assign(entry)
        try commit()
    }

    public func remove(id: UUID) throws {
        guard let record = try record(id: id) else { return }
        context.delete(record)
        try commit()
    }

    private func record(id: UUID) throws -> EntryRecord? {
        let descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.id == id })
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw EntryStoreError.notSaved
        }
    }

    private func nextPosition() throws -> Int {
        var descriptor = FetchDescriptor<EntryRecord>(sortBy: [SortDescriptor(\.position, order: .reverse)])
        descriptor.fetchLimit = 1
        do {
            let newest = try context.fetch(descriptor).first
            return (newest?.position ?? -1) + 1
        } catch {
            throw EntryStoreError.notSaved
        }
    }

    /// A failed commit discards every change made since the last one, so a retry starts from the stored state.
    private func commit() throws {
        do {
            try beforeSave()
            try context.save()
        } catch {
            context.rollback()
            throw EntryStoreError.notSaved
        }
    }
}
