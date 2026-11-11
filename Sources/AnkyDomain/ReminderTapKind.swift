// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReminderTapKind: Equatable, Sendable {
    case dailyReminder, doseDue(UUID), checkIn(UUID), other

    public static func of(identifier: String) -> ReminderTapKind {
        if DailyReminder.isTap(identifier: identifier) {
            return .dailyReminder
        }
        if let medicationID = DoseNotificationPlan.medicationID(fromIdentifier: identifier) {
            return .doseDue(medicationID)
        }
        if let doseID = UUID(uuidString: identifier) {
            return .checkIn(doseID)
        }
        return .other
    }
}
