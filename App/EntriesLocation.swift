// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyStore
import Foundation

enum EntriesLocation {
    static func folder() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: folderName)
    }

    static func storeURL() throws -> URL {
        try StoreFolder.prepare(folder()).appending(path: StoreFolder.entriesFileName)
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
