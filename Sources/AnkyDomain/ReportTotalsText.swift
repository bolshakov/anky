// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The report's totals as the page prints them. `firstEntry` is nil when the period holds doses but no entry.
public struct ReportTotalsText: Equatable, Sendable {
    public let entries: String
    public let doses: String
    public let firstEntry: String?

    public init(summary: ReportSummary, locale: Locale, calendar: Calendar, bundle: Bundle) {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).day().month(.wide)
        entries = String(localized: "\(summary.entryCount) entries", bundle: bundle, locale: locale)
        doses = String(localized: "\(summary.doseCount) doses", bundle: bundle, locale: locale)
        firstEntry = summary.firstEntry.map { first in
            let day = first.formatted(style)
            return String(localized: "First entry \(day)", bundle: bundle, locale: locale)
        }
    }
}
