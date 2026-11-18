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
    var schedule: Data?
    var readingMemory: String?

    init(_ medication: Medication) throws {
        schedule = try medication.schedule.map(StoredSchedule.encoded)
        id = medication.id
        name = medication.name
        strength = medication.strength
        takenAs = medication.takenAs.rawValue
        checkInAfterMinutes = medication.checkInAfter?.rawValue
        createdAt = medication.createdAt
        updatedAt = medication.updatedAt
        archivedAt = medication.archivedAt
        readingMemory = medication.readingMemory?.rawValue
    }

    /// Writes every field except the id and the created time.
    func assign(_ medication: Medication) throws {
        schedule = try medication.schedule.map(StoredSchedule.encoded)
        name = medication.name
        strength = medication.strength
        takenAs = medication.takenAs.rawValue
        checkInAfterMinutes = medication.checkInAfter?.rawValue
        updatedAt = medication.updatedAt
        archivedAt = medication.archivedAt
        readingMemory = medication.readingMemory?.rawValue
    }

    func medication() throws -> Medication {
        guard let takenWay = TakenAs(rawValue: takenAs) else { throw MedicationStoreError.unreadable }
        var checkIn: CheckInDelay?
        if let minutes = checkInAfterMinutes {
            guard let delay = CheckInDelay(rawValue: minutes) else { throw MedicationStoreError.unreadable }
            checkIn = delay
        }
        let memory = try readingMemory.map(Self.readMemory)
        var medication = Medication(id: id, name: name, takenAs: takenWay, createdAt: createdAt)
        medication.strength = strength
        medication.checkInAfter = checkIn
        medication.updatedAt = updatedAt
        medication.archivedAt = archivedAt
        medication.readingMemory = memory
        medication.schedule = try schedule.map(StoredSchedule.read)
        return medication
    }

    private static func readMemory(_ raw: String) throws -> ReadingMemory {
        guard let memory = ReadingMemory(rawValue: raw) else { throw MedicationStoreError.unreadable }
        return memory
    }
}
