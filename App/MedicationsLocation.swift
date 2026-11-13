// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyStore
import Foundation

enum MedicationsLocation {
    static func folder() -> URL {
        EntriesLocation.folder()
    }

    /// The store sits beside the entries store.
    static func fileURL() throws -> URL {
        try StoreFolder.prepare(folder()).appending(path: StoreFolder.medicationsFileName)
    }
}
