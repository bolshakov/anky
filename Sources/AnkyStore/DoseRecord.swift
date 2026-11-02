// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@Model final class DoseRecord {
    var id: UUID
    var medicationID: UUID
    var takenAt: Date
    var checkInAfterMinutes: Int?
    var beforeReadingID: UUID?
    var afterReadingID: UUID?

    init(_ dose: Dose) {
        id = dose.id
        medicationID = dose.medicationID
        takenAt = dose.takenAt
        checkInAfterMinutes = dose.checkInAfter?.rawValue
        beforeReadingID = dose.beforeReadingID
        afterReadingID = dose.afterReadingID
    }

    func dose() throws -> Dose {
        var checkIn: CheckInDelay?
        if let minutes = checkInAfterMinutes {
            guard let delay = CheckInDelay(rawValue: minutes) else { throw MedicationStoreError.unreadable }
            checkIn = delay
        }
        var dose = Dose(id: id, medicationID: medicationID, takenAt: takenAt, beforeReadingID: beforeReadingID)
        dose.afterReadingID = afterReadingID
        dose.checkInAfter = checkIn
        return dose
    }
}
