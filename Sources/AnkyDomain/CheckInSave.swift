// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Saves one check-in: the entry first, then the dose that points at it. Once a save has worked, later calls save
/// nothing, so a second tap on Save check-in cannot make a second entry.
@MainActor public struct CheckInSave {
    public private(set) var isSaved = false
    private let entryID = UUID()
    private var hasAddedEntry = false

    public init() {}

    /// Returns true when this call saved the check-in, false when an earlier call already had. A refused write leaves
    /// the save open. A retry after the entry was written adds nothing and keeps the values it was written with.
    public mutating func save(
        _ draft: EntryDraft,
        for dose: Dose,
        addEntry: (Entry) throws -> Void,
        replaceDose: (Dose) throws -> Void
    ) throws -> Bool {
        guard !isSaved else { return false }
        let entry = Entry(id: entryID, draft: draft)
        if !hasAddedEntry {
            try addEntry(entry)
            hasAddedEntry = true
        }
        var pointing = dose
        pointing.afterReadingID = entry.id
        try replaceDose(pointing)
        isSaved = true
        return true
    }
}
