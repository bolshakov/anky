// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct Dose: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var medicationID: UUID
    public var takenAt: Date
    public var checkInAfter: CheckInDelay?
    public var beforeReadingID: UUID?
    public var afterReadingID: UUID?
    /// Nil for a dose logged before the moment of logging was stored.
    public var loggedAt: Date?

    public init(id: UUID, medicationID: UUID, takenAt: Date, beforeReadingID: UUID? = nil) {
        self.id = id
        self.medicationID = medicationID
        self.takenAt = takenAt
        self.beforeReadingID = beforeReadingID
    }

    // swiftlint:disable:next function_parameter_count
    public static func logged(
        id: UUID, medication: Medication, takenAt: Date, entries: [Entry], manualReadingID: UUID? = nil, loggedAt: Date
    ) -> Dose {
        // #lizard forgives
        var dose = Dose(
            id: id,
            medicationID: medication.id,
            takenAt: takenAt,
            beforeReadingID: ReadingWindow.pick(manualReadingID, in: entries, before: takenAt)?.id
        )
        dose.checkInAfter = medication.checkInAfter
        dose.loggedAt = loggedAt
        return dose
    }

    /// The check-in delay is the dose's own, so a move to another medication does not take that medication's delay.
    public func moved(to medicationID: UUID, at takenAt: Date) -> Dose {
        var dose = self
        dose.medicationID = medicationID
        dose.takenAt = takenAt
        return dose
    }
}
