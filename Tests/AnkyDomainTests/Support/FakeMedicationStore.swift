// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A medication store held in memory. Tests read `addCalls` to see every add, refused ones included.
@MainActor final class FakeMedicationStore: MedicationStore {
    private(set) var contents: [Medication]
    private(set) var addCalls: [Medication] = []
    private(set) var doseContents: [Dose] = []
    /// Set to make the next writes throw. Set back to false to let them succeed.
    var writeFailure = false
    /// Set to make reads throw. Set back to false to let them succeed.
    var readFailure = false

    init(_ medications: [Medication] = [], doses: [Dose] = []) {
        contents = medications
        doseContents = doses
    }

    func all() throws -> [Medication] {
        if readFailure {
            throw MedicationStoreError.unreadable
        }
        return contents
    }

    func add(_ medication: Medication) throws {
        addCalls.append(medication)
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        contents.append(medication)
    }

    func archive(id: UUID, at date: Date) throws {
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        guard let index = contents.firstIndex(where: { $0.id == id }) else {
            throw MedicationStoreError.notSaved
        }
        contents[index].archivedAt = date
    }

    func update(_ medication: Medication) throws {
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        guard let index = contents.firstIndex(where: { $0.id == medication.id }) else {
            throw MedicationStoreError.notSaved
        }
        contents[index] = medication
    }

    func restore(id: UUID) throws {
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        guard let index = contents.firstIndex(where: { $0.id == id }) else {
            throw MedicationStoreError.notSaved
        }
        contents[index].archivedAt = nil
    }

    func doses() throws -> [Dose] {
        if readFailure {
            throw MedicationStoreError.unreadable
        }
        return doseContents
    }

    func logDose(_ dose: Dose) throws {
        if writeFailure {
            throw MedicationStoreError.notSaved
        }
        guard let index = contents.firstIndex(where: { $0.id == dose.medicationID }) else {
            throw MedicationStoreError.notSaved
        }
        doseContents.append(dose)
        contents[index].checkInAfter = dose.checkInAfter
    }
}
