// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum DateTemplateText {
    static func text(for date: Date, template: String, calendar: Calendar, locale: Locale) -> String {
        text(
            for: date,
            dateFormat: DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale),
            calendar: calendar,
            locale: locale
        )
    }

    static func text(for date: Date, dateFormat: String?, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}
