// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ClockText {
    public static func text(for date: Date, calendar: Calendar, locale: Locale) -> String {
        DateTemplateText.text(for: date, template: "jmm", calendar: calendar, locale: locale)
    }
}
