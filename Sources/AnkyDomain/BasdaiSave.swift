// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Saves one BASDAI result. Once a save has worked, later calls add nothing, so a second tap on Save cannot make a
/// second result.
@MainActor public struct BasdaiSave {
    public private(set) var isSaved = false

    public init() {}

    /// Returns true when this call added the result, false when an earlier call already had. A failed add leaves the
    /// save open, so the retry adds a result.
    public mutating func save(
        _ answers: [Int],
        at date: Date,
        add: (BasdaiResult) throws -> Void
    ) throws -> Bool {
        guard !isSaved else { return false }
        guard let result = BasdaiResult(id: UUID(), date: date, answers: answers) else {
            throw BasdaiStoreError.notSaved
        }
        try add(result)
        isSaved = true
        return true
    }
}
