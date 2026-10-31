// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Writes one draft as one medication. Once a write has worked, later calls write nothing, so a second tap on Save
/// cannot make a second medication.
@MainActor public struct MedicationSave {
    private let id: UUID
    public private(set) var isSaved = false

    public init(id: UUID) {
        self.id = id
    }

    /// Returns true when this call wrote the medication, false when an earlier call already had. A failed write
    /// leaves the save open, and a retry writes under the same id.
    public mutating func save(
        _ draft: MedicationDraft,
        at date: Date,
        add: (Medication) throws -> Void
    ) throws -> Bool {
        guard !isSaved else { return false }
        try add(draft.medication(id: id, at: date))
        isSaved = true
        return true
    }
}
