// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DoseTap {
    public enum Outcome: Equatable, Sendable { case open, wait, unavailable }

    /// A `nil` list is one that is not loaded yet: the tap is neither opened nor dropped. A notification can outlive
    /// its medication, so a tap opens Log Dose only while the medication is active.
    public static func outcome(medicationID: UUID, medications: [Medication]?) -> Outcome {
        guard let medications else { return .wait }
        let isActive = medications.contains { $0.id == medicationID && $0.archivedAt == nil }
        return isActive ? .open : .unavailable
    }
}
