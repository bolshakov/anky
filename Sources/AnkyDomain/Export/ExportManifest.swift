// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ExportManifest: Codable, Equatable, Sendable {
    public struct FileRows: Codable, Equatable, Sendable {
        public let name: String
        public let rows: Int
    }

    public let schemaVersion: Int
    public let appVersion: String
    public let build: String
    public let exportedAt: String
    public let files: [FileRows]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case appVersion = "app_version"
        case build
        case exportedAt = "exported_at"
        case files
    }

    /// Sorted keys and no escaped slashes, so two exports of the same data differ only in `exported_at`.
    var json: Data {
        get throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
            return try encoder.encode(self)
        }
    }
}
