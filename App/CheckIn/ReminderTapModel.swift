// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Observation

/// Holds a tap on a check-in reminder until the screens take it, so a tap that launched the app is not lost.
@MainActor @Observable final class ReminderTapModel {
    struct Tap: Equatable {
        let doseID: UUID
        let at: Date
    }

    var pending: Tap?

    /// The reminder's identifier is its dose's id, so any other identifier is not a tap on a check-in reminder.
    func received(identifier: String, at: Date) {
        guard let doseID = UUID(uuidString: identifier) else { return }
        pending = Tap(doseID: doseID, at: at)
    }
}
