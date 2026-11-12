// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The line under the report's title: the period from its first day to today, its length, and the day it was created.
public enum ReportHeaderLine {
    public static func text( // swiftlint:disable:this function_parameter_count
        period: ReportPeriod,
        now: Date,
        locale: Locale,
        calendar: Calendar,
        bundle: Bundle
    ) -> String {
        // #lizard forgives
        let dayMonth = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).day()
            .month(.wide)
        let start = period.start(endingAt: now, calendar: calendar)
        let startStyle = calendar.isDate(start, equalTo: now, toGranularity: .year) ? dayMonth : dayMonth.year()
        let from = start.formatted(startStyle)
        let today = now.formatted(dayMonth.year())
        let length = period.length(bundle: bundle, locale: locale)
        let span = String(localized: "\(from) to \(today)", bundle: bundle, locale: locale)
        let created = String(localized: "created \(today)", bundle: bundle, locale: locale)
        return [span, length, created].joined(separator: RowSecondLine.separator)
    }
}

private extension ReportPeriod {
    func length(bundle: Bundle, locale: Locale) -> String {
        switch self {
        case .oneMonth: String(localized: "1 month", bundle: bundle, locale: locale)
        case .threeMonths: String(localized: "3 months", bundle: bundle, locale: locale)
        case .sixMonths: String(localized: "6 months", bundle: bundle, locale: locale)
        }
    }
}
