// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks and the UI tests. While a file named `fail-basdai-writes` is in the
    /// BASDAI store's folder, every BASDAI write throws, so the real store rolls back. A launch with
    /// `-ANKY_FAIL_BASDAI_WRITES <n>` refuses only its first n writes. Reads are never refused.
    @MainActor
    enum BasdaiWriteSwitch {
        struct Refused: Error {}

        private static var launchRefusalsLeft = UserDefaults.standard.integer(forKey: "ANKY_FAIL_BASDAI_WRITES")

        static func check(folder: URL) throws {
            if launchRefusalsLeft > 0 {
                launchRefusalsLeft -= 1
                throw Refused()
            }
            let flag = folder.appending(path: "fail-basdai-writes")
            if FileManager.default.fileExists(atPath: flag.path) {
                throw Refused()
            }
        }
    }
#endif
