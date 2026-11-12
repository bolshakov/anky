// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The report's totals as the page prints them. `firstEntry` is nil when the period holds doses but no entry, and
/// `basdai` is nil when no BASDAI result goes with the report.
public struct ReportTotalsText: Equatable, Sendable {
    public let entries: String
    public let doses: String
    public let firstEntry: String?
    public let basdai: String?

    public init(summary: ReportSummary, basdaiCount: Int = 0, locale: Locale, calendar: Calendar, bundle: Bundle) {
        // #lizard forgives
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).day().month(.wide)
        entries = String(localized: "\(summary.entryCount) entries", bundle: bundle, locale: locale)
        doses = String(localized: "\(summary.doseCount) doses", bundle: bundle, locale: locale)
        firstEntry = summary.firstEntry.map { first in
            let day = first.formatted(style)
            return String(localized: "First entry \(day)", bundle: bundle, locale: locale)
        }
        basdai = basdaiCount > 0
            ? String(localized: "\(basdaiCount) BASDAI results", bundle: bundle, locale: locale)
            : nil
    }
}
