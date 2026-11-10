// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

/// Holds a tap on a check-in reminder until the screens take it, so a tap that launched the app is not lost.
@MainActor @Observable final class ReminderTapModel {
    struct Tap: Equatable {
        let doseID: UUID
        let at: Date
    }

    var pending: Tap?
    var pendingNewEntry = false

    /// A check-in reminder's identifier is its dose's id, and the daily reminder's is fixed. Any other identifier is
    /// not a tap on a reminder.
    func received(identifier: String, at: Date) {
        if DailyReminder.isTap(identifier: identifier) {
            pendingNewEntry = true
            return
        }
        guard let doseID = UUID(uuidString: identifier) else { return }
        pending = Tap(doseID: doseID, at: at)
    }
}
