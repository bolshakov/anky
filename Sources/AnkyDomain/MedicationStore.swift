// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor public protocol MedicationStore: AnyObject {
    func all() throws -> [Medication]
    func add(_ medication: Medication) throws
    func archive(id: UUID, at date: Date) throws
    func update(_ medication: Medication) throws
    func restore(id: UUID) throws
    func doses() throws -> [Dose]
    /// Stores the dose and sets its medication's saved delay to the dose's, in one save. Throws `notSaved` for a
    /// medication id the store does not hold.
    func logDose(_ dose: Dose) throws
    /// Replaces the stored dose with the same id, every field included. Changes no medication's saved delay. Throws
    /// `notSaved` for a dose id the store does not hold, or a medication id it does not hold.
    func replaceDose(_ dose: Dose) throws
    /// Deletes the stored dose with that id and nothing else. Throws `notSaved` for a dose id the store does not hold.
    func removeDose(id: UUID) throws
}

/// Carries no name, strength or other field, so an error text or log line cannot show a medication.
public enum MedicationStoreError: Error, Equatable {
    case unreadable
    case notSaved
    case unavailable
}
