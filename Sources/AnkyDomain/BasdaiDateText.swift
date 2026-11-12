// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum BasdaiDateText {
    public static func text(for date: Date, calendar: Calendar, locale: Locale) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
                .day().month(.wide).year()
        )
    }
}
