// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor
public extension ExportData {
    /// Reads the stores themselves, not a model's lists, because a model turns a failed read into an empty list and
    /// the export would then look like nothing was logged.
    static func read(entries: any EntryStore, medications: MedicationStore) throws -> ExportData {
        try ExportData(entries: entries.load(), medications: medications.all(), doses: medications.doses())
    }
}
