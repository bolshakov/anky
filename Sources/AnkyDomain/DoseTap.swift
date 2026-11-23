// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DoseTap {
    public enum Outcome: Equatable, Sendable { case open, wait, unavailable }

    /// A notification can outlive its medication, so a tap opens Log Dose only while the medication is active.
    public static func opensLogDose(medicationID: UUID, medications: [Medication]) -> Bool {
        medications.contains { $0.id == medicationID && $0.archivedAt == nil }
    }

    /// A `nil` list is one that is not loaded yet: the tap is neither opened nor dropped.
    public static func outcome(medicationID: UUID, medications: [Medication]?) -> Outcome {
        guard let medications else { return .wait }
        return opensLogDose(medicationID: medicationID, medications: medications) ? .open : .unavailable
    }
}
