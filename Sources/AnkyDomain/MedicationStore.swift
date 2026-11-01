// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@MainActor public protocol MedicationStore: AnyObject {
    func all() throws -> [Medication]
    func add(_ medication: Medication) throws
    func archive(id: UUID, at date: Date) throws
    func update(_ medication: Medication) throws
    func restore(id: UUID) throws
}

/// Carries no name, strength or other field, so an error text or log line cannot show a medication.
public enum MedicationStoreError: Error, Equatable {
    case unreadable
    case notSaved
    case unavailable
}
