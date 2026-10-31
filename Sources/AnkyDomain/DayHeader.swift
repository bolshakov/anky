// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DayHeader: Equatable, Sendable {
    case today
    case yesterday
    case date(Date, includesYear: Bool)

    public func dateText(calendar: Calendar, locale: Locale) -> String? {
        guard case let .date(day, includesYear) = self else {
            return nil
        }
        return DayDateText.text(for: day, includesYear: includesYear, calendar: calendar, locale: locale)
    }
}
