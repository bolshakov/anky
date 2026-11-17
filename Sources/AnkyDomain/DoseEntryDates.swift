// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The dates New Entry takes when it is logged for a dose: it stops at the dose, and starts there unless the dose
/// is still to come.
public struct DoseEntryDates: Equatable, Sendable {
    public let start: Date
    public let latest: Date

    public init(doseAt doseTime: Date, now: Date) {
        start = min(doseTime, now)
        latest = doseTime
    }
}
