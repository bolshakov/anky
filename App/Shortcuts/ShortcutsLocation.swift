// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum ShortcutsLocation {
    static func fileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: folderName).appending(path: "shortcuts.json")
    }

    private static var folderName: String {
        #if DEBUG
            ProcessInfo.processInfo.environment["ANKY_ENTRIES_FOLDER"] ?? "Anky"
        #else
            "Anky"
        #endif
    }
}
