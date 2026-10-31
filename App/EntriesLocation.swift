// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum EntriesLocation {
    static func fileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: folderName).appending(path: "entries.json")
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
