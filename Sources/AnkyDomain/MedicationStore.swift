// SPDX-License-Identifier: GPL-3.0-or-later
@MainActor public protocol MedicationStore: AnyObject {
    func all() throws -> [Medication]
    func add(_ medication: Medication) throws
}

/// Carries no name, strength or other field, so an error text or log line cannot show a medication.
public enum MedicationStoreError: Error, Equatable {
    case unreadable
    case notSaved
    case unavailable
}
