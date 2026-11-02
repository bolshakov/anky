// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct Dose: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var medicationID: UUID
    public var takenAt: Date
    public var checkInAfter: CheckInDelay?
    public var beforeReadingID: UUID?
    public var afterReadingID: UUID?

    public init(id: UUID, medicationID: UUID, takenAt: Date, beforeReadingID: UUID? = nil) {
        self.id = id
        self.medicationID = medicationID
        self.takenAt = takenAt
        self.beforeReadingID = beforeReadingID
    }

    public static func logged(id: UUID, medication: Medication, takenAt: Date, entries: [Entry]) -> Dose {
        var dose = Dose(
            id: id,
            medicationID: medication.id,
            takenAt: takenAt,
            beforeReadingID: ReadingWindow.latest(in: entries, before: takenAt)?.id
        )
        dose.checkInAfter = medication.checkInAfter
        return dose
    }
}
