// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum EntriesLocation {
    static func folder() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: folderName)
    }

    /// The folder is set to complete protection on every call, because `createDirectory` leaves an existing folder's
    /// protection alone.
    static func storeURL() throws -> URL {
        let folder = folder()
        let protection: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: protection
        )
        try FileManager.default.setAttributes(protection, ofItemAtPath: folder.path)
        return folder.appending(path: "entries.store")
    }

    /// Only Debug builds read the variable, so a Release build cannot be pointed at another folder.
    private static var folderName: String {
        #if DEBUG
            ProcessInfo.processInfo.environment["ANKY_ENTRIES_FOLDER"] ?? "Anky"
        #else
            "Anky"
        #endif
    }
}
