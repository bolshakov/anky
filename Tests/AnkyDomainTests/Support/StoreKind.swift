// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData

/// One store under test and the controls the shared suites use. Each `StoreKind` supplies its own.
@MainActor
struct StoreFixture {
    let store: any EntryStore
    let writeCount: @MainActor () -> Int
    let refuseWrites: @MainActor (Bool) -> Void
    let refuseLoads: @MainActor (EntryStoreError?) -> Void
    let reopen: @MainActor () throws -> any EntryStore
}

enum StoreKind: CaseIterable {
    case inMemory
    case swiftData

    @MainActor
    func fixture(holding entries: [Entry]) throws -> StoreFixture {
        switch self {
        case .inMemory:
            let store = InMemoryEntryStore(entries: entries)
            return StoreFixture(
                store: store,
                writeCount: { store.writeCount },
                refuseWrites: { store.refusesWrites = $0 },
                refuseLoads: { store.loadError = $0 },
                reopen: { store }
            )
        case .swiftData:
            let probe = try SwiftDataProbe()
            let url = probe.url
            let store = try SwiftDataEntryStore(url: url, beforeSave: probe.beforeSave)
            for entry in entries {
                try store.add(entry)
            }
            probe.writes = 0
            return StoreFixture(
                store: store,
                writeCount: { probe.writes },
                refuseWrites: { probe.refusesWrites = $0 },
                refuseLoads: { setUnreadableRecord($0 != nil, at: url) },
                reopen: { try SwiftDataEntryStore(url: url, beforeSave: probe.beforeSave) }
            )
        }
    }
}

private struct WriteRefused: Error {}

/// A folder made for one fixture. It is removed when the last object that holds it goes.
private final class ScratchFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Counts the writes that reach the store's commit and refuses them on demand. Every store the fixture makes
/// holds this probe, so the folder lives as long as any of them does.
@MainActor
private final class SwiftDataProbe {
    private let folder: ScratchFolder
    var writes = 0
    var refusesWrites = false

    init() throws {
        folder = try ScratchFolder()
    }

    var url: URL {
        folder.url.appending(path: "entries.store")
    }

    func beforeSave() throws {
        writes += 1
        if refusesWrites {
            throw WriteRefused()
        }
    }
}

/// Adds or removes one row whose kind this build cannot read. The store's own fetch sees it on the next load.
@MainActor
private func setUnreadableRecord(_ present: Bool, at url: URL) {
    guard let container = try? ModelContainer(
        for: EntryRecord.self,
        configurations: ModelConfiguration(url: url)
    ) else { return }
    let context = container.mainContext
    let descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.kind == "unreadable" })
    let rows = (try? context.fetch(descriptor)) ?? []
    if present, rows.isEmpty {
        context.insert(EntryRecord(
            id: UUID(), kind: "unreadable", severity: 4, date: Date(), note: nil, places: [], position: 0
        ))
    }
    if !present {
        rows.forEach { context.delete($0) }
    }
    try? context.save()
}
