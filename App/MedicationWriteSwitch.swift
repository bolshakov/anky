// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks: while a file named `fail-medication-writes` is in the medications folder,
    /// every
    /// medication write throws, so the real store rolls back. Reads are never refused.
    enum MedicationWriteSwitch {
        struct Refused: Error {}

        static func check(folder: URL) throws {
            let flag = folder.appending(path: "fail-medication-writes")
            if FileManager.default.fileExists(atPath: flag.path) {
                throw Refused()
            }
        }
    }
#endif
