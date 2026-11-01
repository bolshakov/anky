// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

/// The entries store is the person's own data: it stays in the device backup, and no error an entry store throws
/// carries an entry's note.
@MainActor
struct SwiftDataEntryStoreSafetyTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    /// An underlying failure that carries a note's text, so a test can check that no error path passes it on.
    private struct MarkedFailure: Error {
        let text: String
    }

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func entry(note: String) throws -> Entry {
        try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: date,
            note: note,
            places: []
        )
    }

    private func writeRecord(_ record: EntryRecord, to url: URL) throws {
        let container = try ModelContainer(for: EntryRecord.self, configurations: ModelConfiguration(url: url))
        container.mainContext.insert(record)
        try container.mainContext.save()
    }

    private func assertNoText(_ error: any Error, holds marker: String) {
        #expect(!String(describing: error).contains(marker))
        #expect(!String(reflecting: error).contains(marker))
        #expect(!error.localizedDescription.contains(marker))
    }

    @Test func savedStoreStaysInBackup() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let store = try SwiftDataEntryStore(url: url)
            try store.add(entry(note: "Walk note"))

            let excluded = try URL(filePath: url.path).resourceValues(forKeys: [.isExcludedFromBackupKey])
            #expect(excluded.isExcludedFromBackup == false)
        }
    }

    @Test func aRefusedWriteThrowsNotSavedWithoutTheNoteText() throws {
        try withFolder { folder in
            let marker = "Refused-NoteMarker"
            let store = try SwiftDataEntryStore(url: folder.appending(path: "entries.store")) {
                throw MarkedFailure(text: marker)
            }
            let error = try #require(throws: EntryStoreError.self) { try store.add(entry(note: marker)) }
            #expect(error == .notSaved)
            assertNoText(error, holds: marker)
        }
    }

    @Test func anUnreadableRecordThrowsUnreadableWithoutTheNoteText() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let marker = "Unreadable-NoteMarker"
            let record = EntryRecord(
                id: UUID(), kind: "headache", severity: 4, date: date, note: marker, places: [], position: 0
            )
            try writeRecord(record, to: url)
            let error = try #require(throws: EntryStoreError.self) { try SwiftDataEntryStore(url: url).load() }
            #expect(error == .unreadable)
            assertNoText(error, holds: marker)
        }
    }

    @Test func aStoreThatCannotOpenThrowsUnavailableWithoutTheOpenErrorText() throws {
        let marker = "Locked-NoteMarker"
        let store = DeferredEntryStore { throw MarkedFailure(text: marker) }
        let error = try #require(throws: EntryStoreError.self) { try store.load() }
        #expect(error == .unavailable)
        assertNoText(error, holds: marker)
    }
}
