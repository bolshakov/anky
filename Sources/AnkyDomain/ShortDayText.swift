// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ShortDay: Equatable, Sendable {
    case today
    case yesterday
    case sameYear(String)
    case otherYear(day: String, year: String)
}

public enum ShortDayText {
    public static func day(for date: Date, now: Date, calendar: Calendar, locale: Locale) -> ShortDay {
        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }
        let previousDay = calendar.date(byAdding: .day, value: -1, to: now)
        if let previousDay, calendar.isDate(date, inSameDayAs: previousDay) {
            return .yesterday
        }
        let day = DateTemplateText.text(for: date, template: "EEEdMMM", calendar: calendar, locale: locale)
        guard calendar.component(.year, from: date) != calendar.component(.year, from: now) else {
            return .sameYear(day)
        }
        let year = DateTemplateText.text(for: date, template: "y", calendar: calendar, locale: locale)
        return .otherYear(day: day, year: year)
    }
}
