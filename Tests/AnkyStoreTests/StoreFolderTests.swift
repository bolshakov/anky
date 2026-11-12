// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyStore
import Foundation
import Testing

struct StoreFolderTests {
    /// Some volumes, such as the GitHub macOS runner, reject complete protection with EINVAL. The probe makes the two
    /// calls `prepare` makes and reports unsupported only when they throw.
    private static let protectionIsSupported: Bool = {
        let root = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let scratch = root.appending(path: "probe", directoryHint: .isDirectory)
        let protection: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        do {
            try FileManager.default.createDirectory(
                at: scratch,
                withIntermediateDirectories: true,
                attributes: protection
            )
            try FileManager.default.setAttributes(protection, ofItemAtPath: scratch.path)
            return true
        } catch {
            return false
        }
    }()

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

    @Test(.enabled(if: protectionIsSupported)) func aMissingFolderIsCreatedWithCompleteProtection() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)

            #expect(FileManager.default.fileExists(atPath: folder.path))
            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test(.enabled(if: protectionIsSupported)) func aMissingFolderIsCreatedWithItsParents() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Support/Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)

            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test(.enabled(if: protectionIsSupported)) func anExistingFolderIsProtectedAndKeepsItsFile() throws {
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

    @Test(.enabled(if: protectionIsSupported)) func preparingTwiceDoesNotThrowAndKeepsTheProtection() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            try StoreFolder.prepare(folder)
            try StoreFolder.prepare(folder)

            #expect(try protection(of: folder) == .complete)
        }
    }

    @Test(.enabled(if: protectionIsSupported)) func prepareReturnsTheFolderItWasGiven() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            let prepared = try StoreFolder.prepare(folder)

            #expect(prepared == folder)
        }
    }

    @Test func theTwoStoresSitInOneFolderUnderTheirOwnNames() throws {
        try withTemporaryDirectory { root in
            let folder = root.appending(path: "Anky", directoryHint: .isDirectory)

            let entries = folder.appending(path: StoreFolder.entriesFileName)
            let medications = folder.appending(path: StoreFolder.medicationsFileName)

            #expect(entries.deletingLastPathComponent().standardizedFileURL == folder.standardizedFileURL)
            #expect(medications.deletingLastPathComponent().standardizedFileURL == folder.standardizedFileURL)
            #expect(entries.lastPathComponent == "entries.store")
            #expect(medications.lastPathComponent == "medications.store")
        }
    }
}
