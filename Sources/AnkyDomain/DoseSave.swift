// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Logs one dose. Once a log has worked, later calls log nothing, so a second tap on Save cannot make a second dose.
@MainActor public struct DoseSave {
    public private(set) var isSaved = false

    public init() {}

    /// Returns true when this call logged the dose, false when an earlier call already had. A failed log leaves the
    /// save open, so the retry logs the same dose.
    public mutating func save(_ dose: Dose, log: (Dose) throws -> Void) throws -> Bool {
        guard !isSaved else { return false }
        try log(dose)
        isSaved = true
        return true
    }
}
