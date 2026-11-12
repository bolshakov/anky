// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum StoreFolder {
    public static let entriesFileName = "entries.store"
    public static let medicationsFileName = "medications.store"

    /// Sets complete protection on every call, because `createDirectory` leaves an existing folder's protection alone.
    @discardableResult
    public static func prepare(_ folder: URL) throws -> URL {
        let protection: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: protection
        )
        try FileManager.default.setAttributes(protection, ofItemAtPath: folder.path)
        return folder
    }
}
