// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public protocol TipProgressStore: Sendable {
    func load() -> TipProgress
    func save(_ progress: TipProgress) throws
}

public struct FileTipProgressStore: TipProgressStore {
    private static let currentVersion = 1

    private let fileURL: URL
    private let protection: FileProtection

    public init(fileURL: URL, protection: FileProtection) {
        self.fileURL = fileURL
        self.protection = protection
    }

    public func load() -> TipProgress {
        guard
            let data = try? Data(contentsOf: fileURL),
            let header = try? JSONDecoder().decode(VersionHeader.self, from: data),
            header.version == Self.currentVersion,
            let file = try? JSONDecoder().decode(ProgressFile.self, from: data)
        else { return TipProgress() }
        return TipProgress(visits: file.visits, picks: file.picks)
    }

    public func save(_ progress: TipProgress) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let file = ProgressFile(version: Self.currentVersion, visits: progress.visits, picks: progress.picks)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(file).write(to: fileURL, options: writingOptions)
    }

    private var writingOptions: Data.WritingOptions {
        switch protection {
        case .complete: [.atomic, .completeFileProtection]
        case .deviceDefault: [.atomic]
        }
    }
}

private struct VersionHeader: Decodable {
    let version: Int
}

private struct ProgressFile: Codable {
    let version: Int
    let visits: Int
    let picks: [String: Int]
}
