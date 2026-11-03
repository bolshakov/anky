// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks and the UI tests. While a file named `fail-medication-writes` is in the
    /// medications folder, every medication write throws, so the real store rolls back. A launch with
    /// `-ANKY_FAIL_MEDICATION_WRITES <n>` refuses only its first n writes. Reads are never refused.
    @MainActor
    enum MedicationWriteSwitch {
        struct Refused: Error {}

        private static var launchRefusalsLeft = UserDefaults.standard.integer(forKey: "ANKY_FAIL_MEDICATION_WRITES")

        static func check(folder: URL) throws {
            if launchRefusalsLeft > 0 {
                launchRefusalsLeft -= 1
                throw Refused()
            }
            let flag = folder.appending(path: "fail-medication-writes")
            if FileManager.default.fileExists(atPath: flag.path) {
                throw Refused()
            }
        }
    }
#endif
