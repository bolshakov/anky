// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@Model final class MedicationRecord {
    var id: UUID
    var name: String
    var strength: String?
    var takenAs: String
    var checkInAfterMinutes: Int?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(_ medication: Medication) {
        id = medication.id
        name = medication.name
        strength = medication.strength
        takenAs = medication.takenAs.rawValue
        checkInAfterMinutes = medication.checkInAfter?.rawValue
        createdAt = medication.createdAt
        updatedAt = medication.updatedAt
        archivedAt = medication.archivedAt
    }

    func medication() throws -> Medication {
        guard let takenWay = TakenAs(rawValue: takenAs) else { throw MedicationStoreError.unreadable }
        var checkIn: CheckInDelay?
        if let minutes = checkInAfterMinutes {
            guard let delay = CheckInDelay(rawValue: minutes) else { throw MedicationStoreError.unreadable }
            checkIn = delay
        }
        var medication = Medication(id: id, name: name, takenAs: takenWay, createdAt: createdAt)
        medication.strength = strength
        medication.checkInAfter = checkIn
        medication.updatedAt = updatedAt
        medication.archivedAt = archivedAt
        return medication
    }
}
