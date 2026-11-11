// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

/// Holds a tap on a reminder until the screens take it, so a tap that launched the app is not lost.
@MainActor @Observable final class ReminderTapModel {
    struct Tap: Equatable {
        let doseID: UUID
        let at: Date
    }

    var pending: Tap?
    var pendingNewEntry = false
    var pendingLogDose: UUID?

    func received(identifier: String, at: Date) {
        switch ReminderTapKind.of(identifier: identifier) {
        case .dailyReminder: pendingNewEntry = true
        case let .doseDue(medicationID): pendingLogDose = medicationID
        case let .checkIn(doseID): pending = Tap(doseID: doseID, at: at)
        case .other: break
        }
    }
}
