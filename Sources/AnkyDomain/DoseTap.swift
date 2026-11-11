// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DoseTap {
    /// A notification can outlive its medication, so a tap opens Log Dose only while the medication is active.
    public static func opensLogDose(medicationID: UUID, medications: [Medication]) -> Bool {
        medications.contains { $0.id == medicationID && $0.archivedAt == nil }
    }
}
