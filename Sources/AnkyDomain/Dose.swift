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
        id: UUID, medication: Medication, takenAt: Date, entries: [Entry], manualReadingID: UUID? = nil,
        linkedReadingID: UUID? = nil, noReading: Bool = false, loggedAt: Date
    ) -> Dose {
        // #lizard forgives
        var dose = Dose(
            id: id,
            medicationID: medication.id,
            takenAt: takenAt,
            beforeReadingID: ReadingLink.resolve(
                linked: linkedReadingID, manual: manualReadingID, noReading: noReading, in: entries, at: takenAt
            )?.id
        )
        dose.checkInAfter = medication.checkInAfter
        dose.loggedAt = loggedAt
        return dose
    }

    /// The check-in delay is the dose's own, so a move to another medication does not take that medication's delay.
    /// `afterReadingID` is double-optional so that leaving it out keeps the stored after reading, `.some(nil)` clears
    /// it, and a plain id or optional variable replaces it. A bare `nil` literal also keeps it.
    public func moved(
        to medicationID: UUID, at takenAt: Date, beforeReadingID: UUID?, afterReadingID: UUID?? = nil
    ) -> Dose {
        var dose = self
        dose.medicationID = medicationID
        dose.takenAt = takenAt
        dose.beforeReadingID = beforeReadingID
        if let afterReadingID {
            dose.afterReadingID = afterReadingID
        }
        return dose
    }

    /// The time compares at the minute, since the date wheel drops the seconds a saved dose carries. Leaving out
    /// `afterReadingID` counts the stored after reading as unchanged.
    public func isMoved(
        to medicationID: UUID, at takenAt: Date, beforeReadingID: UUID?, afterReadingID: UUID?? = nil,
        calendar: Calendar = .current
    ) -> Bool {
        // #lizard forgives
        medicationID != self.medicationID
            || beforeReadingID != self.beforeReadingID
            || afterReadingID.map { $0 != self.afterReadingID } ?? false
            || !calendar.isDate(takenAt, equalTo: self.takenAt, toGranularity: .minute)
    }
}
