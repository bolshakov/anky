// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The line under the Report screen's period: what the period holds, from its first day to today.
public enum ReportCountsLine {
    public static func text( // swiftlint:disable:this function_parameter_count
        summary: ReportSummary,
        period: ReportPeriod,
        now: Date,
        locale: Locale,
        calendar: Calendar,
        bundle: Bundle
    ) -> String {
        // #lizard forgives
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).day().month(.wide)
        let from = period.start(endingAt: now, calendar: calendar).formatted(style)
        let to = now.formatted(style)
        guard !summary.isEmpty else {
            return String(
                localized: "Nothing logged from \(from) to \(to). Pick a longer period.",
                bundle: bundle,
                locale: locale
            )
        }
        let entries = String(localized: "\(summary.entryCount) entries", bundle: bundle, locale: locale)
        let doses = String(localized: "\(summary.doseCount) doses", bundle: bundle, locale: locale)
        return String(localized: "\(entries) and \(doses), \(from) to \(to).", bundle: bundle, locale: locale)
    }
}
