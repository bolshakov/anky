// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum MedicationsLocation {
    static func folder() -> URL {
        EntriesLocation.folder()
    }

    /// The store sits beside the entries store. The folder is set to complete protection on every call, because
    /// `createDirectory` leaves an existing folder's protection alone.
    static func fileURL() throws -> URL {
        let folder = folder()
        let protection: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: protection
        )
        try FileManager.default.setAttributes(protection, ofItemAtPath: folder.path)
        return folder.appending(path: "medications.store")
    }
}
