// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum EditDoseMedications {
    /// The active medications, then the dose's own medication when it is archived. An active one is already in the
    /// first part, so it is never listed twice.
    public static func choices(for dose: Dose, in medications: [Medication]) -> [Medication] {
        let ownArchived = medications.filter { $0.id == dose.medicationID && $0.archivedAt != nil }
        return MedicationOrder.active(medications) + ownArchived
    }
}
