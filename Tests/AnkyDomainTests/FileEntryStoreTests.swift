import AnkyDomain
import Foundation
import Testing

struct FileEntryStoreTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(kind: EntryKind = .pain, severity: Int = 4, note: String = "") throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(severity)), date: date)
        draft.kind = kind
        draft.note = note
        return Entry(draft: draft)
    }

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func missingFileReadsAsNoEntries() throws {
        try withFolder { folder in
            let store = FileEntryStore(fileURL: folder.appending(path: "entries.json"), protection: .deviceDefault)
            let loaded = try store.load()
            #expect(loaded.isEmpty)
        }
    }

    @Test func keepsEveryFieldInSaveOrderThroughSaveAndLoad() throws {
        try withFolder { folder in
            let store = FileEntryStore(fileURL: folder.appending(path: "entries.json"), protection: .deviceDefault)
            let first = try entry(kind: .stiffness, severity: 0, note: "Walk note")
            let second = try entry(kind: .fatigue, severity: 10)
            let third = try entry(kind: .pain, severity: 6, note: "Stairs")
            let saved = [first, second, third]
            try store.save(saved)
            let loaded = try store.load()
            #expect(loaded == saved)
        }
    }

    @Test func loadThrowsUnreadableForBytesItCannotDecode() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            try Data("this is not an entries file".utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            #expect(throws: EntryStoreError.unreadable) { try store.load() }
        }
    }

    @Test func unreadableFileIsKept() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            try Data("this is not an entries file".utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            let before = try Data(contentsOf: fileURL)

            #expect(throws: EntryStoreError.unreadable) {
                try store.save([entry(note: "Walk note")])
            }

            let after = try Data(contentsOf: fileURL)
            #expect(after == before)
        }
    }

    @Test func newerVersionFileIsLeftAsItWas() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let newer = Data(#"{"entries":[{"mood":"calm","id":"x"}],"version":2}"#.utf8)
            try newer.write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)

            #expect(throws: EntryStoreError.newerVersion(2)) { try store.load() }
            #expect(throws: EntryStoreError.newerVersion(2)) { try store.save([]) }

            let after = try Data(contentsOf: fileURL)
            #expect(after == newer)
        }
    }

    @Test func failedSaveLeavesTheEarlierFileWhole() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            let earlier = try [entry(note: "Walk note")]
            try store.save(earlier)
            let before = try Data(contentsOf: fileURL)

            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder.path)
            defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path) }
            #expect(throws: (any Error).self) { try store.save([entry(note: "Stairs")]) }

            let after = try Data(contentsOf: fileURL)
            #expect(after == before)
            let loaded = try store.load()
            #expect(loaded == earlier)
        }
    }

    @Test func savedFileStaysInBackup() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            try store.save([entry(note: "Walk note")])

            let excluded = try URL(filePath: fileURL.path).resourceValues(forKeys: [.isExcludedFromBackupKey])
            #expect(excluded.isExcludedFromBackup == false)
        }
    }

    @Test func errorTextNeverCarriesEntryContent() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let marker = "notakind-WalkNoteMarker"
            let file = """
            {"entries":[{"id":"\(UUID())","kind":"\(marker)","date":"2026-10-26T08:15:00Z","severity":4}],"version":1}
            """
            try Data(file.utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)

            let error = try #require(throws: EntryStoreError.self) { try store.load() }
            #expect(error == .unreadable)
            #expect(!String(describing: error).contains(marker))
            #expect(!String(reflecting: error).contains(marker))
            #expect(!error.localizedDescription.contains(marker))
        }
    }

    @Test func writesVersionOneWithSortedKeysPrettyPrintedAndWholeSecondDates() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            let id = try #require(UUID(uuidString: "3F2C0E4B-1A2B-4C3D-8E9F-0A1B2C3D4E5F"))
            let moment = try #require(ISO8601DateFormatter().date(from: "2026-10-26T08:15:00Z"))
            let draft = try EntryDraft(severity: #require(Severity(4)), date: moment)
            try store.save([Entry(id: id, draft: draft)])

            let text = try String(contentsOf: fileURL, encoding: .utf8)
            #expect(text == """
            {
              "entries" : [
                {
                  "date" : "2026-10-26T08:15:00Z",
                  "id" : "3F2C0E4B-1A2B-4C3D-8E9F-0A1B2C3D4E5F",
                  "kind" : "pain",
                  "places" : [

                  ],
                  "severity" : 4
                }
              ],
              "version" : 1
            }
            """)
        }
    }
}
