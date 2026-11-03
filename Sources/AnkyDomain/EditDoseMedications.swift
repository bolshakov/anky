// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum EditDoseMedications {
    /// The active medications and the dose's own medication, even when it is archived, in created order.
    public static func choices(for dose: Dose, in medications: [Medication]) -> [Medication] {
        medications
            .filter { $0.archivedAt == nil || $0.id == dose.medicationID }
            .sorted { $0.createdAt < $1.createdAt }
    }
}
