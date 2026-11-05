// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct CheckInReminder: Equatable, Sendable {
    public let doseID: UUID
    public let fireAt: Date

    public init(doseID: UUID, fireAt: Date) {
        self.doseID = doseID
        self.fireAt = fireAt
    }
}

public extension CheckInDue {
    /// One per dose whose due moment `d` is after `now` and for which `waiting(..., now: d)` contains the dose,
    /// firing at `d`. Defined by `waiting`, never by rules of its own.
    static func reminders(doses: [Dose], medications: [Medication], entries: [Entry], now: Date) -> [CheckInReminder] {
        doses.compactMap { dose in
            guard let due = dueMoment(of: dose, medications: medications, entries: entries), due > now,
                  waiting(doses: doses, medications: medications, entries: entries, now: due)
                      .contains(where: { $0.id == dose.id })
            else {
                return nil
            }
            return CheckInReminder(doseID: dose.id, fireAt: due)
        }
    }
}
