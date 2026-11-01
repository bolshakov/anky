// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum MedicationOrder {
    public static func active(_ all: [Medication]) -> [Medication] {
        all
            .filter { $0.archivedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }
}
