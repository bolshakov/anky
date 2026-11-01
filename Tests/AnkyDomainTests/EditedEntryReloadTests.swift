// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct EditedEntryReloadTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(severity: Int = 4) throws -> Entry {
        try Entry(draft: EntryDraft(severity: #require(Severity(severity)), date: date))
    }

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func aChangedLevelSurvivesAReloadFromTheFile() throws {
        try withFolder { folder in
            let store = FileEntryStore(fileURL: folder.appending(path: "entries.json"), protection: .deviceDefault)
            var log = EntryLog(store: store)
            let original = try entry(severity: 4)
            try log.add(original)

            try log.replace(Entry(id: original.id, draft: EntryDraft(severity: #require(Severity(6)), date: date)))

            let reloaded = EntryLog(store: store)
            #expect(reloaded.entries.count == 1)
            #expect(reloaded.entries.first?.severity == Severity(6))
        }
    }

    @Test func aRemovedEntryStaysGoneAfterAReloadFromTheFile() throws {
        try withFolder { folder in
            let store = FileEntryStore(fileURL: folder.appending(path: "entries.json"), protection: .deviceDefault)
            var log = EntryLog(store: store)
            let removed = try entry()
            try log.add(removed)
            try log.add(entry())

            try log.remove(id: removed.id)

            #expect(EntryLog(store: store).entries.count == 1)
        }
    }
}
