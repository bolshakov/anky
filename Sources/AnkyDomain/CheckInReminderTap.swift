// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReminderTapDestination: Equatable, Sendable {
    case checkIn(Dose)
    case today
}

public extension CheckInDue {
    /// Check In when the tapped reminder's dose is still offered at `now`, otherwise Today. Defined by `waiting`, so
    /// the window rules are never copied here.
    static func destination( // swiftlint:disable:this function_parameter_count
        forReminderOf doseID: UUID,
        doses: [Dose],
        medications: [Medication],
        entries: [Entry],
        now: Date
    ) -> ReminderTapDestination {
        // #lizard forgives
        let offered = waiting(doses: doses, medications: medications, entries: entries, now: now)
        guard let dose = offered.first(where: { $0.id == doseID }) else { return .today }
        return .checkIn(dose)
    }
}
