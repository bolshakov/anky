// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation

    /// Debug builds only, for the walks: while a file named `slow-export` is in the entries folder, each export waits
    /// before it finishes, so a walk can see and hear "Exporting".
    enum ExportSlowSwitch {
        static let hold: Duration = .seconds(3)

        static func isOn(folder: URL) -> Bool {
            FileManager.default.fileExists(atPath: folder.appending(path: "slow-export").path)
        }
    }
#endif
