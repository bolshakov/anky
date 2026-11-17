// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum MedicationScheduleLine {
    public static func text( // swiftlint:disable:this function_parameter_count
        takenAs: TakenAs,
        schedule: MedicationSchedule?,
        locale: Locale,
        calendar: Calendar,
        bundle: Bundle
    ) -> String {
        // #lizard forgives
        switch (takenAs, schedule) {
        case (.asNeeded, _):
            String(localized: "As needed", bundle: bundle, locale: locale)
        case let (.scheduled, schedule?):
            schedule.words(locale: locale, calendar: calendar, bundle: bundle)
        case (.scheduled, nil):
            String(localized: "Not set", bundle: bundle, locale: locale)
        }
    }

    public static func footnote( // swiftlint:disable:this function_parameter_count
        schedule: MedicationSchedule,
        now: Date,
        locale: Locale,
        calendar: Calendar,
        bundle: Bundle
    ) -> String {
        // #lizard forgives
        let words = schedule.words(locale: locale, calendar: calendar, bundle: bundle)
        guard let next = schedule.nextDoses(after: now, count: 1, calendar: calendar).first else {
            return String(localized: "\(words).", bundle: bundle, locale: locale)
        }
        let day = dayWithWeekdayComma(next, calendar: calendar, locale: locale)
        return String(localized: "\(words). Next: \(day).", bundle: bundle, locale: locale)
    }

    private static func dayWithWeekdayComma(_ day: Date, calendar: Calendar, locale: Locale) -> String {
        let text = DayDateText.text(for: day, includesYear: false, calendar: calendar, locale: locale)
        let weekday = day.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide)
        )
        let rest = text.dropFirst(weekday.count)
        guard text.lowercased(with: locale).hasPrefix(weekday.lowercased(with: locale)),
              rest.first?.isWhitespace == true
        else {
            return text
        }
        return text.prefix(weekday.count) + "," + rest
    }
}
