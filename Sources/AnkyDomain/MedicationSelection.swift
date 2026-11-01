// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum MedicationSelection {
    public static func kept(_ selected: UUID?, in active: [Medication]) -> UUID? {
        if let selected, active.contains(where: { $0.id == selected }) {
            return selected
        }
        return active.first?.id
    }
}
