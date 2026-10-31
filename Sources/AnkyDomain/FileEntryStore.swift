// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct FileEntryStore: EntryStore {
    private static let currentVersion = 1

    private let fileURL: URL
    private let protection: FileProtection

    public init(fileURL: URL, protection: FileProtection) {
        self.fileURL = fileURL
        self.protection = protection
    }

    public func load() throws -> [Entry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        guard let data = try? Data(contentsOf: fileURL) else { throw EntryStoreError.unreadable }
        return try Self.entries(from: data)
    }

    public func save(_ entries: [Entry]) throws {
        // A file this version cannot read is refused here, so it is never overwritten.
        _ = try load()
        try write(EntriesFile(version: Self.currentVersion, entries: entries))
    }

    private func write(_ file: EntriesFile) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try Self.encoder().encode(file)
        try data.write(to: fileURL, options: writingOptions)
    }

    private var writingOptions: Data.WritingOptions {
        switch protection {
        case .complete: [.atomic, .completeFileProtection]
        case .deviceDefault: [.atomic]
        }
    }

    /// The version is read before the entries, so a file from a newer app is reported as newer
    /// rather than as unreadable, whatever its entries look like.
    private static func entries(from data: Data) throws -> [Entry] {
        guard let version = (try? decoder().decode(VersionHeader.self, from: data))?.version else {
            throw EntryStoreError.unreadable
        }
        if version > currentVersion {
            throw EntryStoreError.newerVersion(version)
        }
        guard version == currentVersion, let file = try? decoder().decode(EntriesFile.self, from: data) else {
            throw EntryStoreError.unreadable
        }
        return file.entries
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct VersionHeader: Decodable {
    let version: Int
}

private struct EntriesFile: Codable {
    let version: Int
    let entries: [Entry]
}
