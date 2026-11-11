// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReportPeriod: CaseIterable, Sendable {
    case oneMonth, threeMonths, sixMonths

    var months: Int {
        switch self {
        case .oneMonth: 1
        case .threeMonths: 3
        case .sixMonths: 6
        }
    }

    /// A day missing from the earlier month clamps to that month's last day, so the start never passes `now`.
    public func start(endingAt now: Date, calendar: Calendar) -> Date {
        let sameDay = calendar.date(byAdding: .month, value: -months, to: now) ?? now
        return calendar.startOfDay(for: sameDay)
    }
}
