// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftData

@Model final class DoseRecord {
    var id: UUID
    var medicationID: UUID
    var takenAt: Date
    var painBefore: Int
    var checkInAfterMinutes: Int?
    var painAfter: Int?
    var checkedInAt: Date?

    init(_ dose: Dose) {
        id = dose.id
        medicationID = dose.medicationID
        takenAt = dose.takenAt
        painBefore = dose.painBefore.value
        checkInAfterMinutes = dose.checkInAfter?.rawValue
        painAfter = dose.painAfter?.value
        checkedInAt = dose.checkedInAt
    }

    func dose() throws -> Dose {
        guard let before = Severity(painBefore) else { throw MedicationStoreError.unreadable }
        var checkIn: CheckInDelay?
        if let minutes = checkInAfterMinutes {
            guard let delay = CheckInDelay(rawValue: minutes) else { throw MedicationStoreError.unreadable }
            checkIn = delay
        }
        var after: Severity?
        if let value = painAfter {
            guard let severity = Severity(value) else { throw MedicationStoreError.unreadable }
            after = severity
        }
        var dose = Dose(id: id, medicationID: medicationID, takenAt: takenAt, painBefore: before, checkInAfter: checkIn)
        dose.painAfter = after
        dose.checkedInAt = checkedInAt
        return dose
    }
}
