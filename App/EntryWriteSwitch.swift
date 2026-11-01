// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks: while a file named `fail-entry-writes` is in the entries folder, every entry
    /// write throws, so the real store rolls back. Reads are never refused.
    enum EntryWriteSwitch {
        struct Refused: Error {}

        static func check(folder: URL) throws {
            let flag = folder.appending(path: "fail-entry-writes")
            if FileManager.default.fileExists(atPath: flag.path) {
                throw Refused()
            }
        }
    }
#endif
