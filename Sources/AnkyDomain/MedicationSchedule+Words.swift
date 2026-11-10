// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

extension MedicationSchedule {
    /// The schedule as one sentence. Weekday and time names come from the system for `locale`, and each repeat shape
    /// is one whole catalog key, so a sentence is never joined from translated pieces.
    public func words(locale: Locale, calendar: Calendar, bundle: Bundle) -> String {
        let times = SpokenList.joined(times.map { Self.clockText($0, locale: locale) }, locale: locale)
        switch `repeat` {
        case let .days(interval):
            return interval == 1
                ? String(localized: "Every day at \(times)", bundle: bundle, locale: locale)
                : String(localized: "Every \(interval) days at \(times)", bundle: bundle, locale: locale)
        case let .weeks(interval, weekdays):
            let days = Self.weekdayNames(weekdays, calendar: calendar, locale: locale)
            return interval == 1
                ? String(localized: "Every week on \(days) at \(times)", bundle: bundle, locale: locale)
                : String(localized: "Every \(interval) weeks on \(days) at \(times)", bundle: bundle, locale: locale)
        case let .months(interval, day):
            return interval == 1
                ? String(localized: "Every month on day \(day) at \(times)", bundle: bundle, locale: locale)
                : String(
                    localized: "Every \(interval) months on day \(day) at \(times)", bundle: bundle, locale: locale
                )
        }
    }

    private static func clockText(_ time: DoseTime, locale: Locale) -> String {
        let calendar = Calendar.gregorian(in: .gmt)
        let moment = calendar.date(from: DateComponents(
            year: 2001,
            month: 1,
            day: 1,
            hour: time.hour,
            minute: time.minute
        ))
        return moment.map { ClockText.text(for: $0, calendar: calendar, locale: locale) } ?? ""
    }

    private static func weekdayNames(_ weekdays: Set<Locale.Weekday>, calendar: Calendar, locale: Locale) -> String {
        var named = calendar
        named.locale = locale
        named.firstWeekday = calendar.firstWeekday
        let ordered = (0 ..< 7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        let names = ordered
            .filter { number in weekdays.contains { $0.number == number } }
            .map { named.standaloneWeekdaySymbols[$0 - 1] }
        return SpokenList.joined(names, locale: locale)
    }
}

private extension Locale.Weekday {
    var number: Int {
        switch self {
        case .sunday: 1
        case .monday: 2
        case .tuesday: 3
        case .wednesday: 4
        case .thursday: 5
        case .friday: 6
        case .saturday: 7
        @unknown default: 0
        }
    }
}
