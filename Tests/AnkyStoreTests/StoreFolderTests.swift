// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyStore
import Foundation
import Testing

struct StoreFolderTests {
    private func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        return try body(root)
    }

    private func protection(of folder: URL) throws -> FileProtectionType? {
        try FileManager.default.attributesOfItem(atPath: folder.path)[.protectionKey] as? FileProtectionType
    }

    @Test func aMissingFolderIsCreatedWithCompleteProtection() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)

            #expect(FileManager.default.fileExists(atPath: folder.path))
            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test func aMissingFolderIsCreatedWithItsParents() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Support/Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)

            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test func anExistingFolderIsProtectedAndKeepsItsFile() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: folder.path)
            let file = folder.appending(path: StoreFolder.entriesFileName)
            try Data("stored".utf8).write(to: file)
            #expect(try protection(of: folder) != .complete)

            try StoreFolder.prepare(folder)

            #expect(try Data(contentsOf: file) == Data("stored".utf8))
            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test func preparingTwiceDoesNotThrowAndKeepsTheProtection() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)
            try StoreFolder.prepare(folder)

            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test func prepareReturnsTheFolderItWasGiven() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            let prepared = try StoreFolder.prepare(folder)

            #expect(prepared == folder)
        }
    }

    @Test func theTwoStoresSitInOnePreparedFolder() throws {
        try withTemporaryDirectory { root in
            let folder = try StoreFolder.prepare(root.appending(path: "Anky", directoryHint: .isDirectory))

            let entries = folder.appending(path: StoreFolder.entriesFileName)
            let medications = folder.appending(path: StoreFolder.medicationsFileName)

            #expect(entries.deletingLastPathComponent().standardizedFileURL == folder.standardizedFileURL)
            #expect(medications.deletingLastPathComponent().standardizedFileURL == folder.standardizedFileURL)
            #expect(entries.lastPathComponent == "entries.store")
            #expect(medications.lastPathComponent == "medications.store")
        }
    }
}
